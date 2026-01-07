import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
import pandas as pd

# Set up figure parameters
side = 0.6
r = side / np.cos(np.radians(30))
a = 2 * side
offset_x = 0.5
offset_y = 1.4
vertical_offset = side * np.sqrt(3)

# File paths
path = '/filepath/'
df_ssp = pd.read_csv(f'{path}uncertainty_score_production_loss_change_345_nd_585.csv')
df_cooler_hotter = pd.read_csv(f'{path}uncertainty_score_production_loss_change_cooler_nd_hotter.csv')

df_ssp = df_ssp[df_ssp['scenario'] == 'NF']
df_cooler_hotter = df_cooler_hotter[df_cooler_hotter['scenario'] == 'NF']

# Define region positions and abbreviations
regions = [
    'Northwest', 'N. Great Plains', 'Midwest', 'Northeast',
    'Southwest', 'S. Great Plains', 'Southeast'
]
abbreviations = ['NW', 'NGP', 'MW', 'NE', 'SW', 'SGP', 'SE']

positions = [
    {'x': offset_x, 'y': offset_y},
    {'x': offset_x + a, 'y': offset_y},
    {'x': offset_x + 2 * a, 'y': offset_y},
    {'x': offset_x + 3 * a, 'y': offset_y},
    {'x': offset_x + 0.5 * a, 'y': offset_y - vertical_offset},
    {'x': offset_x + 1.5 * a, 'y': offset_y - vertical_offset},
    {'x': offset_x + 2.5 * a, 'y': offset_y - vertical_offset}
]

# Define crops and scenarios
crops = ['corn', 'wheat', 'soybean']
scenarios = ['345_vs_585', 'Cooler_vs_Hotter']  
# Define subplot labels
subplot_labels = ['(a1)', '(a2)', '(b1)', '(b2)', '(c1)', '(c2)']  

# Create a single figure with 3x2 grid
fig, axes = plt.subplots(3, 2, figsize=(18, 8), sharex=True, sharey=True)
axes = axes.flatten()  # Flatten the 3x2 array for easier indexing

# Get all uncertainty scores for consistent normalization (excluding NaN)
valid_scores_ssp = df_ssp['uncertainty_score'].dropna().values
valid_scores_cooler_hotter = df_cooler_hotter['uncertainty_score'].dropna().values
valid_scores = np.concatenate([valid_scores_ssp, valid_scores_cooler_hotter])
norm = plt.Normalize(0.0, 0.3)  # Fixed normalization range for consistency

# Create colormap
cmap = plt.get_cmap('YlOrRd')  
# Plot each subplot
for idx, (crop, scenario) in enumerate([(c, s) for c in crops for s in scenarios]):
    ax = axes[idx]
    ax.set_aspect('equal')
    ax.set_xlim(-0.5, 5.0)
    ax.set_ylim(-0.4, 2.4)
    ax.axis('off')

    # Select the appropriate DataFrame based on the scenario
    if scenario == '345_vs_585':
        data_uncertainty = df_ssp[df_ssp['crop'] == crop]
    else:  # Cooler_vs_Hotter
        data_uncertainty = df_cooler_hotter[df_cooler_hotter['crop'] == crop]

    # Map uncertainty scores to regions
    uncertainty_dict = dict(zip(data_uncertainty['region_name'], data_uncertainty['uncertainty_score']))

    # Prepare data for plotting
    plot_regions = []
    for region, pos, abbr in zip(regions, positions, abbreviations):
        unc_score = uncertainty_dict.get(region)
        if pd.isna(unc_score):
            unc_score = None  # Mark as no data if NaN
        plot_regions.append({'x': pos['x'], 'y': pos['y'], 'label': abbr, 'unc_score': unc_score})

    # Draw hexagons
    for region in plot_regions:
        if region['unc_score'] is not None:
            color = cmap(norm(region['unc_score']))
            text = f'{region["unc_score"]:.2f}'  # Display uncertainty score
            text_color = 'black'
        else:
            color = (0.9, 0.9, 0.9)  # Light gray for missing data
            text = 'N/A'  # Display N/A for missing data
            text_color = 'gray'
        hexagon = patches.RegularPolygon(
            (region['x'], region['y']), numVertices=6, radius=r,
            orientation=0,  # Point-top orientation
            facecolor=color,
            edgecolor='black',
            linewidth=1
        )
        ax.add_patch(hexagon)
        # Display abbreviation and uncertainty score
        ax.text(region['x'], region['y'] , region['label'],
                ha='center', va='center', fontsize=8, color='black')

    ax.text(0.06, 0.2, subplot_labels[idx], transform=ax.transAxes,
            ha='left', va='top', fontsize=12)
    

row_positions = [0.75, 0.5, 0.25]  
for crop, y_pos in zip(crops, row_positions):
    fig.text(0.3, y_pos, crop.capitalize(), ha='right', va='center', fontsize=12, rotation=90)

fig.text(0.4, 0.89, 'atm45_ssp3 vs atm85_ssp5', ha='center', va='center', fontsize=12)
fig.text(0.6, 0.89, 'Cooler vs Hotter', ha='center', va='center', fontsize=12)

# Add a single colorbar at the bottom
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array(valid_scores)
cbar = fig.colorbar(sm, ax=axes.ravel().tolist(), orientation='horizontal', fraction=0.02, pad=0.05,extend='max')
cbar.set_ticks([0, 0.1, 0.2, 0.3])
cbar.ax.tick_params(labelsize=14)

cbar.ax.text(0.563, 1.275, 'Increasing Divergence', ha='right', va='top', fontsize=12)
# Add caption below colorbar
fig.text(0.496, 0.152, 'Uncertainty Scores (0 to 1)',
         ha='center', va='top', fontsize=12) # 'Uncertainty scores (1 - |corr.|)'

plt.subplots_adjust(wspace=0.0, hspace=0.0, left=0.3, right=0.7, top=0.9, bottom=0.16)

# Save the figure
plt.savefig(f'{path}/uncertainty_score_NF_345_vs_585_and_cooler_vs_hotter.png', format='png', bbox_inches='tight', dpi=300)
