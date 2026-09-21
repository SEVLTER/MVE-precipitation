# {targets} pipeline for constructing precipitation histories in MVE plots

# Load packages required to define the pipeline
library(targets)
library(tarchetypes)
library(fs)

# Set target options
tar_option_set()

# Source R scripts
tar_source()

# Prepare directories
dir_create("output")

# Define the target list
list()
