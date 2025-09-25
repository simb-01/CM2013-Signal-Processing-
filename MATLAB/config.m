% -- Project Configuration --

% Set the current iteration of the project (1-4).
% This controls which parts of the pipeline are active.
CURRENT_ITERATION = 1;

% Set to true to use cached data for preprocessing and feature extraction.
USE_CACHE = true;

% -- File Paths --
DATA_DIR = '../data/';
TRAINING_DIR = [DATA_DIR 'training/'];
HOLDOUT_DIR = [DATA_DIR 'holdout/'];
CACHE_DIR = 'cache/';

% -- Preprocessing --
LOW_PASS_FILTER_FREQ = 40; % Hz

% -- Feature Extraction --
% (Add feature-specific parameters here)

% -- Classification --
% Parameters for the k-NN classifier for iteration 1
KNN_N_NEIGHBORS = 5;

% -- Submission --
SUBMISSION_FILE = 'submission.csv';
