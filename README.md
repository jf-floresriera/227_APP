# 🌽 227_APP

## Spatio-Temporal Digital Platform for Remote Sensing-Based Monitoring and Modeling of Foliar Diseases in Maize Crops

[![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue.svg)]()
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-green.svg)]()
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue.svg)]()
[![PostGIS](https://img.shields.io/badge/PostGIS-Geospatial-orange.svg)]()
[![Docker](https://img.shields.io/badge/Docker-Containerized-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)]()

---

# Overview

The 227_APP project is a next-generation digital agriculture platform designed for the acquisition, management, analysis, visualization, and prediction of foliar diseases in maize crops through the integration of:

* Remote sensing technologies
* Mobile data acquisition
* Geospatial information systems (GIS)
* Artificial intelligence
* Spatial epidemiology
* Decision support systems

The platform has been developed as part of a Master of Science research project in Agricultural Sciences at the Universidad Nacional de Colombia and aims to bridge the gap between advanced sensing technologies and operational disease management tools for precision agriculture.

---

# Scientific Motivation

Maize is one of the most important crops worldwide, with annual production exceeding one billion tons.

However, foliar diseases continue to generate significant yield losses, while current monitoring approaches are typically:

* Labor-intensive
* Subjective
* Time-consuming
* Spatially limited

Recent advances in remote sensing, machine learning, and spatial analytics provide opportunities for early disease detection and predictive disease management.

Nevertheless, most existing solutions remain fragmented and do not offer a fully integrated framework capable of combining:

* Field observations
* Remote sensing data
* Artificial intelligence models
* Spatial analysis
* Temporal forecasting
* Decision support systems

This project addresses that gap.

---

# Research Hypothesis

The integration of multimodal remote sensing data with spatio-temporal analytical models within a unified digital platform significantly improves the early detection, quantification, and prediction of foliar diseases in maize production systems under real-world field conditions.

---

# General Objective

Develop a modular digital platform capable of integrating remote sensing data, field observations, spatial analytics, and machine learning models for the monitoring and prediction of foliar diseases in maize crops.

---

# System Architecture

The platform follows a multi-layer architecture.

```text
┌─────────────────────────────┐
│ Data Acquisition Layer      │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ Data Storage Layer          │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ Processing Layer            │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ AI & Modeling Layer         │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ Visualization Layer         │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ Decision Support Layer      │
└─────────────────────────────┘
```

---

# Core Technologies

## Frontend

### Flutter

Cross-platform mobile application framework.

Features:

* Android deployment
* iOS deployment
* Responsive UI
* Offline-first operation

### Riverpod

State management architecture providing:

* Reactive programming
* Dependency injection
* Scalable application design

### Drift Database

Local persistence layer enabling:

* Offline data collection
* Local storage
* Synchronization workflows

---

# Backend

## FastAPI

High-performance RESTful API framework.

Features:

* Automatic OpenAPI documentation
* Asynchronous execution
* JWT authentication
* Scalability

### Main Services

```text
/auth
/users
/fields
/sampling
/observations
/diseases
/models
/reports
```

---

# Database Layer

## PostgreSQL

Primary relational database.

## PostGIS

Spatial extension providing support for:

* Geometries
* Polygons
* Spatial indexing
* Spatial queries
* Geostatistical workflows

Supported spatial entities:

```text
Fields
Sampling points
Disease observations
Risk maps
Administrative boundaries
Remote sensing layers
```

---

# Mobile Data Collection

The platform supports field data collection through smartphones.

Collected variables include:

* Disease incidence
* Disease severity
* Crop growth stage
* Agronomic observations
* Geolocation
* Images
* Audio records

---

# Multimedia Integration

## RGB Imagery

Supported formats:

```text
JPEG
PNG
WEBP
HEIC
```

Applications:

* Disease detection
* Severity estimation
* Deep learning training

## Audio

Supported formats:

```text
MP3
WAV
M4A
OGG
```

Applications:

* Voice notes
* Field observations
* Expert annotations

---

# Sampling Framework

The platform incorporates multiple epidemiological sampling strategies.

### Random Sampling

Suitable for unbiased disease estimation.

### Systematic Sampling

Grid-based monitoring.

### Directed Sampling

Focused monitoring of suspected hotspots.

### Transect Sampling

Spatial disease gradient analysis.

---

# Artificial Intelligence Integration

The architecture is designed to support machine learning and deep learning workflows.

Current and future models include:

### Classification

* Random Forest
* XGBoost
* Support Vector Machines

### Deep Learning

* MobileNet
* ResNet50
* EfficientNet
* YOLOv8
* YOLO11
* Vision Transformers

### Segmentation

* U-Net
* DeepLabV3+
* SegFormer

### Time Series Forecasting

* LSTM
* GRU
* Temporal CNN

---

# Remote Sensing Integration

## Proximal Sensing

* Smartphones
* RGB Cameras

## UAV Platforms

Products:

* Orthomosaics
* DSM
* DTM
* Vegetation indices

## Satellite Data

### Sentinel-2

Bands:

```text
B2
B3
B4
B5
B6
B7
B8
B8A
B11
B12
```

### MODIS

Applications:

* Phenology
* Productivity monitoring

### Landsat

Applications:

* Long-term temporal analysis

---

# Geospatial Analytics

The platform supports advanced spatial analysis.

### Spatial Statistics

* Moran's I
* Local Indicators of Spatial Association (LISA)

### Geostatistics

* Variograms
* Ordinary Kriging
* Universal Kriging

### Risk Mapping

* Disease hotspots
* Disease spread analysis
* Spatio-temporal clusters

---

# Decision Support System

The ultimate goal of the platform is to generate actionable information for producers and researchers.

Outputs include:

* Disease incidence maps
* Severity maps
* Risk maps
* Temporal alerts
* Technical reports
* Early warning systems

---

# Docker Infrastructure

The project is fully containerized.

Services:

```text
Flutter Client
FastAPI Backend
PostgreSQL
PostGIS
NGINX
```

Benefits:

* Reproducibility
* Scalability
* Portability

---

# Future Roadmap

### Phase I

* Core mobile platform
* Geospatial database
* Disease observations

### Phase II

* Remote sensing integration
* AI model deployment
* Automated analytics

### Phase III

* Real-time monitoring
* Early warning system
* National-scale deployment

---

# Research Impact

The platform contributes to:

* Precision agriculture
* Digital agriculture
* Plant disease epidemiology
* Remote sensing applications
* Artificial intelligence in agriculture
* Decision support systems

---

# Development Team

### Jesús Enrique Flores-Riera

Master's Candidate

Universidad Nacional de Colombia

Faculty of Agricultural Sciences

---

### Thesis Director

Joaquín Guillermo Ramírez-Gil

Universidad Nacional de Colombia

---

# Acknowledgments

Laboratorio de Agrocomputación y Análisis Epidemiológico

Faculty of Agricultural Sciences

Universidad Nacional de Colombia

---

# Citation

If you use this repository in your research, please cite:

Flores-Riera, J. E., & Ramírez-Gil, J. G. (2026). Spatio-Temporal Digital Platform for Remote Sensing-Based Monitoring and Modeling of Foliar Diseases in Maize Crops. Universidad Nacional de Colombia.

---

# License

MIT License
