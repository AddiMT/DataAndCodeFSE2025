# -*- coding: utf-8 -*-
import subprocess
import sys

# Function to install required packages
def install_packages():
    required_packages = ["pandas", "numpy", "matplotlib", "lifelines"]
    for package in required_packages:
        try:
            __import__(package)  # Try to import the package
        except ImportError:
            print(f"Installing missing package: {package}")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# Install packages before importing
install_packages()

# Now, import the required packages
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from lifelines import KaplanMeierFitter
from lifelines.utils import restricted_mean_survival_time

# Function to load dataset with error handling
def load_dataset(file_path1='../aP4-t.csv', file_path2='/content/aP4-t.csv'):
    try:
        df = pd.read_csv(file_path1, sep=";")
    except FileNotFoundError:
        print(f"File not found at {file_path1}, trying {file_path2}...")
        df = pd.read_csv(file_path2, sep=";")
    print(f"Dataset loaded with shape: {df.shape}")
    return df

# Function to preprocess dataset for Kaplan-Meier analysis
def preprocess_data(df):
    scidf = df.query("isSci == 1").copy()
    
    # Convert timestamps
    scidf['LatestCommitTemp'] = (scidf['LatestCommitDate'].astype(int) / (3600 * 24 * 365.25)) + 1970
    valid_data_mask = scidf['LatestCommitTemp'] <= 2023.8
    df_filtered = scidf[valid_data_mask].copy()

    # Compute duration in years
    df_filtered['duration'] = (df_filtered['LatestCommitDate'] - df_filtered['EarliestCommitDate']) / 3600 / 24 / 365.35
    df_filtered['event'] = np.where((df_filtered['LatestCommitDate'].astype(int) / 3600 / 365.25 / 24 + 1970) <= 2023, 1, 0)

    return df_filtered

# Function for Kaplan-Meier analysis by field
def kaplan_meier_by_field(df_filtered):
    print("\nRunning Kaplan-Meier Analysis by Field...")
    plt.figure(figsize=(8, 5))
    kmf = KaplanMeierFitter()
    line_styles = ['-', '--', '-.', ':']
    
    average_survival_times = {}

    # Calculate RMST for all projects
    kmf.fit(df_filtered['duration'], event_observed=df_filtered['event'])
    print("RMST across all projects:", restricted_mean_survival_time(kmf, t=15))

    # Kaplan-Meier curve for each field
    for i, (name, grouped_df) in enumerate(df_filtered.groupby('Field')):
        kmf.fit(grouped_df['duration'], event_observed=grouped_df['event'], label=name)
        kmf.plot_survival_function(ci_show=True, linestyle=line_styles[i % len(line_styles)])
        average_survival_times[name] = restricted_mean_survival_time(kmf, t=15)

    print("Average survival times by Field:", average_survival_times)

    # Customize plot
    plt.xlabel('Duration (Years)', fontsize=14)
    plt.ylabel('Survival Probability', fontsize=14)
    plt.xlim(0, 15)
    plt.legend(title='Field', fontsize=10, title_fontsize=11, ncol=2, columnspacing=0.4)
    plt.grid(True)

    # Save and show the plot
    plt.savefig('kaplan_meier_curves_by_field_15_years.png', dpi=300, bbox_inches='tight')
    plt.savefig('kaplan_meier_curves_by_field_15_years.pdf', format='pdf', dpi=300, bbox_inches='tight')
    plt.show()

# Function for Kaplan-Meier analysis by Layer
def kaplan_meier_by_layer(df_filtered):
    print("\nRunning Kaplan-Meier Analysis by Layer...")
    plt.figure(figsize=(8, 5))
    kmf = KaplanMeierFitter()
    line_styles = ['-', '--', '-.', ':']

    average_survival_times = {}

    # Convert layer names to sentence case for consistency
    df_filtered['LayerName'] = df_filtered['LayerName'].str.lower().str.capitalize()

    # Kaplan-Meier curve for each Layer
    for i, (name, grouped_df) in enumerate(df_filtered.groupby('LayerName')):
        kmf.fit(grouped_df['duration'], event_observed=grouped_df['event'], label=name)
        kmf.plot_survival_function(ci_show=True, linestyle=line_styles[i % len(line_styles)])
        average_survival_times[name] = restricted_mean_survival_time(kmf, t=15)

    print("Average survival times by Layer:", average_survival_times)

    # Customize plot
    plt.xlabel('Duration (Years)', fontsize=14)
    plt.ylabel('Survival Probability', fontsize=14)
    plt.xlim(0, 15)
    plt.legend(title='Layer Name', fontsize=10.5, title_fontsize=11)
    plt.grid(True)

    # Save and show the plot
    plt.savefig('kaplan_meier_curves_by_layer_15_years.png', dpi=300, bbox_inches='tight')
    plt.savefig('kaplan_meier_curves_by_layer_15_years.pdf', format='pdf', dpi=300, bbox_inches='tight')
    plt.show()

# Main function to execute pipeline
def main():
    print("\nStarting Kaplan-Meier Analysis Pipeline...\n")
    
    # Load and preprocess dataset
    dataset = load_dataset()
    filtered_data = preprocess_data(dataset)
    
    # Run Kaplan-Meier analysis
    kaplan_meier_by_field(filtered_data)
    kaplan_meier_by_layer(filtered_data)

    print("\nAnalysis Complete!")

# Run the script only when executed directly
if __name__ == "__main__":
    main()
