############################################ the first part of the figure 
from scipy.stats import pearsonr
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

clm_df = pd.read_csv("regional_sri_clm.csv", index_col="time")
grfr_df = pd.read_csv("regional_sri_grfr.csv", index_col="time")

clm_df.index = pd.to_datetime(clm_df.index)
grfr_df.index = pd.to_datetime(grfr_df.index)

# Define regions and corresponding labels
regions = ['NE', 'SE', 'MW', 'NGP', 'SGP', 'NW', 'SW']
labels = ['(a1)', '(a2)', '(a3)', '(a4)', '(a5)', '(a6)', '(a7)']

# Verify that both dataframes have the same regions
assert set(clm_df.columns) == set(grfr_df.columns) == set(regions), "Region columns do not match"

# Create individual scatter plots for each region
for region, label in zip(regions, labels):

    plt.figure(figsize=(4, 4))  
    
    # Extract SRI values for the region
    clm_sri = clm_df[region]
    grfr_sri = grfr_df[region]
    
    # Drop NaN pairs for correlation
    valid = clm_sri.notna() & grfr_sri.notna()
    clm_valid = clm_sri[valid]
    grfr_valid = grfr_sri[valid]
    
    # Calculate Pearson correlation
    if len(clm_valid) > 1:  # Ensure enough data points
        r, _ = pearsonr(clm_valid, grfr_valid)
        print(f"{region}: r = {r:.2f}")
    else:
        print(f"{region}: Insufficient data for correlation")
        r = np.nan
    
    # Scatter plot
    plt.scatter( grfr_sri, clm_sri, alpha=0.5, s=20)
    
    # Determine the same range for x and y axes
    min_val = min(clm_sri.min(), grfr_sri.min())
    max_val = max(clm_sri.max(), grfr_sri.max())
    # Round limits to nearest 0.5 for consistent tick intervals
    axis_min = np.floor(min_val / 0.5) * 0.5
    axis_max = np.ceil(max_val / 0.5) * 0.5
    
    # Set same limits for both axes
    plt.xlim(axis_min, axis_max)
    plt.ylim(axis_min, axis_max)
    
    # Set same ticks for both axes with 0.5 interval
    ticks = np.arange(axis_min, axis_max + 0.5, 1.0)
    plt.xticks(ticks, fontsize=12)
    plt.yticks(ticks, fontsize=12)
    
    # Add 1:1 line
    plt.plot([axis_min, axis_max], [axis_min, axis_max], 'r--', label='1:1 line')
    
    # Set labels and title
    plt.ylabel('CLM5 SRI', fontsize=14)
    plt.xlabel('GRFR SRI', fontsize=14)
    plt.title(f'{label} {region} (r={r:.2f})', fontsize=14)
    plt.legend(loc='lower right')
    
    plt.gca().set_aspect('equal', adjustable='box')
    
    plt.tight_layout()
    plt.savefig(f'clm_grfr_sri_scatter_{region}.png')
    plt.close()
    
    
    
############################################ the second part of the figure    
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress, pearsonr
import matplotlib.ticker as ticker
import pandas as pd


path = '/path_to_data_dir/'
df_usda = pd.read_csv(f'{path}state_corn_usda_1981-2015.csv')
df_usda['Value'] = pd.to_numeric(df_usda['Value'].str.replace(',', ''), errors='coerce')

area_target_items = [
'CORN, GRAIN - ACRES HARVESTED'
]
df_usda_area = df_usda[df_usda['Data Item'].isin(area_target_items)]
usda_harvested_area = df_usda_area[['State', 'Year', 'Value']].rename(columns={'Value': 'Harvest_Area(acre)'})

production_target_items = [
'CORN, GRAIN - PRODUCTION, MEASURED IN BU'
]


df_usda_production = df_usda[df_usda['Data Item'].isin(production_target_items)]
usda_production = df_usda_production[['State', 'Year', 'Value']].rename(columns={'Value': 'Production(BU)'})
usda_merged = pd.merge(usda_harvested_area ,usda_production , on = ['State','Year'])

usda_merged['Yield_bu_per_acre'] = usda_merged['Production(BU)'] / usda_merged['Harvest_Area(acre)']



df_clm = pd.read_csv('corn_1981-2015.csv')
state_list = list(np.unique(df_usda['State']))


df_clm_filtered = df_clm[df_clm['State_Name'].isin(state_list)]


df_clm_filtered['Yield_bu_per_acre'] = df_clm_filtered['Production(BU)'] / (df_clm_filtered['Harvest_Area(km^2)']*247.105)

df_clm_clear = df_clm_filtered[['State_Name', 'Year', 'Yield_bu_per_acre','Production(BU)','Harvest_Area(km^2)']]

comparison = pd.merge(
    usda_merged,
    df_clm_clear,
    left_on=['State', 'Year'],
    right_on=['State_Name', 'Year'],
    suffixes=('_usda', '_clm')
)

fig, ax = plt.subplots(1, 1, figsize=(4, 4))

plt.scatter(comparison['Production(BU)_usda']/39.368,comparison['Production(BU)_clm']/39.368, color='blue',s=10) # convert the unit from bu to ton
correlation_coefficient, p_value = pearsonr(comparison['Production(BU)_usda'],comparison['Production(BU)_clm'])
print ('correlation_coefficient, p_value',correlation_coefficient, p_value)

states = ['IOWA', 'ILLINOIS', 'MINNESOTA','INDIANA','NEBRASKA','SOUTH DAKOTA','WISCONSIN','OHIO','MISSOURI','KANSAS']
comparison_selected = comparison[comparison['State_Name'].isin(states)]

correlation_coefficient_selected, p_value_selected = pearsonr(comparison_selected['Production(BU)_usda'],comparison_selected['Production(BU)_clm'])
print ('correlation_coefficient_selected, p_value_selected',correlation_coefficient_selected, p_value_selected)

corr_text = f"Pearson r = {correlation_coefficient:.3f}\np-value = {p_value:.3f}"
plt.text(
    0.05, 0.95, corr_text,
    transform=plt.gca().transAxes,
    verticalalignment='top',
    fontsize=10,
    bbox=dict(boxstyle="round", facecolor="white", alpha=0.6)
)

plt.ylim(5e1,1e8)
plt.xlim(5e3,1e8)
plt.xscale('log')
plt.yscale('log')

ax = plt.gca()
ax.xaxis.set_minor_locator(ticker.LogLocator(base=10.0, subs='auto', numticks=10))
ax.yaxis.set_minor_locator(ticker.LogLocator(base=10.0, subs='auto', numticks=10))

ax.xaxis.set_major_locator(ticker.LogLocator(base=10.0, numticks=10))
ax.yaxis.set_major_locator(ticker.LogLocator(base=10.0, numticks=10))

ax.xaxis.set_minor_formatter(ticker.NullFormatter())
ax.yaxis.set_minor_formatter(ticker.NullFormatter())

plt.title('(b1) Corn annual production (ton)')
plt.xlabel('USDA-NASS',fontsize=12)
plt.ylabel('CLM5',fontsize=12)
plt.tick_params(axis='both', labelsize=12) 
plt.tight_layout()
plt.savefig('USDA_vs_CLM_corn_state-year.png', dpi=500, bbox_inches='tight')


############################################ the first part of the figure 
import pandas as pd
import numpy as np 
import matplotlib.pyplot as plt
from scipy.stats import spearmanr
from scipy.stats import pearsonr

# Calculate ubRMSE (Unbiased RMSE) for each crop
def calculate_ubrmse(predictions, observations):
    x_mean = np.mean(predictions)
    y_mean = np.mean(observations)
    ub_rmse = np.sqrt(np.mean((predictions - x_mean - (observations - y_mean))**2))
    return ub_rmse


price = 'projected_price'
path = '/path_to_base_dir/'
df1_corn = pd.read_csv(path + 'corn_insurance_drought.csv')
df2_corn = pd.read_csv(path + 'corn_production_loss_hist_cl100.csv')
df3_corn = pd.read_csv(path + 'corn_price.csv')


df1_corn['State'] = df1_corn['State'].str.upper()  # Convert to uppercase to match df2
df1_corn['payment_per_acreage'] = df1_corn['Payment Indemnity']/df1_corn['Payment Acreage']
df2_corn = df2_corn.merge(df3_corn[['Year', price]], on='Year', how='left')

conversion_factor_corn = 39.368  # corn 1 ton = 39.368 bushels
df2_corn['economy_loss'] = df2_corn['Production_Loss(ton)'] * conversion_factor_corn * df2_corn[price]
df2_corn['loss_per_acreage'] = df2_corn['economy_loss']/(df2_corn['Area_Loss(km^2)']*247.105)
df1_corn = df1_corn[(df1_corn['Year'] >= 2001) & (df1_corn['Year'] <= 2015)]
df2_corn = df2_corn[(df2_corn['Year'] >= 2001) & (df2_corn['Year'] <= 2015)]
df2_corn = df2_corn.rename(columns={'State_Name': 'State'})
df_merged_corn = pd.merge(df1_corn[['Year', 'State', 'payment_per_acreage']], df2_corn[['Year', 'State', 'loss_per_acreage']], on=['Year', 'State'], how='inner')

# List of states to keep after merging, total corn area of these 10 states account for 76% of the CONUS corn area
states = ['IOWA', 'ILLINOIS', 'MINNESOTA','INDIANA','NEBRASKA','SOUTH DAKOTA','WISCONSIN','OHIO','MISSOURI','KANSAS']
states_to_keep_corn = [state.upper() for state in states]

# Filter the merged DataFrame to keep only the selected states
df_merged_filtered_corn = df_merged_corn[df_merged_corn['State'].isin(states_to_keep_corn)]
df_merged_filtered_corn = df_merged_filtered_corn.fillna(0)

fig, ax = plt.subplots(1, 1, figsize=(4, 4))

plt.scatter(df_merged_filtered_corn['payment_per_acreage'], df_merged_filtered_corn ['loss_per_acreage'], color='blue', label='Corn',s=25)
plt.xlim(0, 500)
plt.ylim(0, 500)
plt.xlabel('Indemnity Payments ($/acre) ',fontsize=12)
plt.ylabel('Estimated Financial Losses ($/acre)',fontsize=12)
plt.tick_params(axis='both', labelsize=12) 
df_clean_corn = df_merged_filtered_corn.dropna(subset=['loss_per_acreage', 'payment_per_acreage'])
spearman_corr_corn, p_value_corn = spearmanr(df_clean_corn['loss_per_acreage'], df_clean_corn['payment_per_acreage'])
print(f"Spearman Correlation_corn: {spearman_corr_corn:.4f}")
print(f"P-value_corn: {p_value_corn:.4f}")

slope_corn, intercept_corn, _, _, _ = linregress(df_clean_corn['payment_per_acreage'], df_clean_corn['loss_per_acreage'])

ub_rmse_corn = calculate_ubrmse(df_clean_corn['loss_per_acreage'], df_clean_corn['payment_per_acreage'])

# Calculate Pearson correlation for corn
pearson_corr_corn, p_value_corn = pearsonr(df_clean_corn['loss_per_acreage'], df_clean_corn['payment_per_acreage'])
print(f"Pearson Correlation for Corn: {pearson_corr_corn:.4f}")
print(f"P-value for Pearson Correlation: {p_value_corn:.4f}")

corr_text = f"Pearson r = {pearson_corr_corn:.3f}\np-value = {p_value_corn:.3f}\nub-rmse={ub_rmse_corn:.1f} $/acre"
plt.text(
    0.05, 0.95, corr_text,
    transform=plt.gca().transAxes,
    verticalalignment='top',
    fontsize=10,
    bbox=dict(boxstyle="round", facecolor="white", alpha=0.6)
)

plt.xticks(np.arange(0, 501, 100))  
plt.yticks(np.arange(0, 501, 100))  
plt.title('(c1) Corn')  # Added r to title
plt.tight_layout()
print(f"ubRMSE for Corn: {ub_rmse_corn:.4f}")

save_path = 'CLM_vs_AgRiskViewer_scatter_corn.png'
plt.savefig(save_path, format='png',bbox_inches='tight')