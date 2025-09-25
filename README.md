# Sleep Scoring Project

Welcome to the Sleep Scoring Project! This repository contains a modular framework for developing an automatic sleep scoring system, available in both Python and MATLAB.

## Project Overview

This project is designed to guide students through the process of building a biomedical signal processing pipeline. It emphasizes an agile, iterative development approach, allowing for progressive enhancement of the system's capabilities.

## Getting Started

To begin, choose your preferred language (Python or MATLAB) and explore the respective jumpstart project:

*   **[Python Jumpstart](./Python/README.md)**
*   **[MATLAB Jumpstart](./MATLAB/README.md)**

Each jumpstart project provides a baseline implementation, including data loading, preprocessing, feature extraction, classification, visualization, and reporting modules. It also includes a mechanism for generating submission files for competition.

## Project Management and Iteration Planning

For detailed information on project planning, iterative development, team organization, and technical implementation guidelines, please refer to the **[Project Management Guide](./Project_Management_Guide.md)**.

## Data

The `data/` directory at the root of this repository contains:

*   **`data/training/`**: Labeled EDF and XML files for training and validation.
*   **`data/holdout/`**: Unlabeled EDF files for final inference and competition submission.

## Competition Submission

Students are expected to submit a CSV file with predicted sleep stages for the hold-out data. The format should be `record_number,epoch_number,label`.

Good luck with your project! 🚀
