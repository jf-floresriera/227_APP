from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import create_access_token, get_current_user_id
from app.crud import user as user_crud
from app.schemas.auth import UserCreate, UserOut, Token, PasswordChange

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    """Registrar un nuevo usuario."""
    existing = await user_crud.get_by_email(db, payload.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = await user_crud.create(db, payload)
    return user


@router.post("/token", response_model=Token)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    """
    Obtener JWT. Usar con `Authorization: Bearer <token>`.
    Form fields: `username` (email) + `password`.
    """
    user = await user_crud.authenticate(db, email=form.username, password=form.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")

    token = create_access_token(subject=user.id)
    return Token(
        access_token=token,
        user=UserOut(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            is_active=user.is_active,
        ),
    )


@router.get("/me", response_model=UserOut)
async def get_me(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Retornar el perfil del usuario autenticado."""
    user = await user_crud.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    payload: PasswordChange,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    from app.core.security import verify_password, hash_password
    from sqlalchemy import update
    from app.models.user import User

    user = await user_crud.get_by_id(db, user_id)
    if not user or not verify_password(payload.current_password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Wrong current password")

    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(hashed_password=hash_password(payload.new_password))
    )
    await db.commit()
