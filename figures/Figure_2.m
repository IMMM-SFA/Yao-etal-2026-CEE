%% this is the Matlab script to view features over CONUS
clear all; clc;
lat = load('lat_2d.txt');
lon = load('lon_2d.txt');
data = load('conus_cell_hist.txt');

monthly_data = data(:,3);
coor = data(:,1:2); coor(:,2) = coor(:,2) - 360;
row_idx = NaN(length(monthly_data), 1);  % Row indices for latitudes
col_idx = NaN(length(monthly_data), 1);  % Column indices for longitudes
% Loop through each data point in the coordinates and find the corresponding row and column
for i = 1:length(monthly_data)
    lat_val = coor(i, 1);  % Latitude value
    lon_val = coor(i, 2);  % Longitude value

    % Find row index where lat matches
    row_mask = (lat == lat_val);
    col_mask = (lon == lon_val);

    % Find the intersection of row and column indices
    [row, col] = find(row_mask & col_mask);

    % Store indices if a match is found
    if ~isempty(row) && ~isempty(col)
        row_idx(i) = row(1);  % Store the first match
        col_idx(i) = col(1);
    end
end


us_coor = load('us_coor.txt');
r1 = load('R1_nw.txt');
r2 = load('R2_sw.txt');
r3 = load('R3_ngp.txt');
r4 = load('R4_sgp.txt');
r5 = load('R5_mw.txt');
r6 = load('R6_se.txt');
r7 = load('R7_ne.txt');
b_line = 3;
num_year = 35;


%% LULC change, prepare the data
hist = load('conus_cell_hist.txt');
cluster = hist(:,1:3);

lat_nc = ncread('Annual_P_timeseries_hist.nc', 'lat');
lon_nc = ncread('Annual_P_timeseries_hist.nc', 'lon'); 

% Define parameters
scenarios = {'ssp3_rcp45', 'ssp5_rcp85'};
climates  = {'cooler', 'hotter'};
vars      = {'corn_nonirri', 'wheat_nonirri', 'soybean_nonirri'};


% Initialize structures
data_near_hot = struct();
data_near_cool  = struct();
t_data    = struct();

% Process near-future (2021–2055)
for i = 1:length(scenarios)
    scenario = scenarios{i};
    for k = 1:length(vars)
        varname = vars{k};
        j=1;
        climate = climates{j};
        file_name = ['wheat_corn_soybean_' scenario '_' climate '_2021-2055_timeseries.nc'];
        var_data = ncread(file_name, varname);
        % Average of cooler and hotter
        data_near_cool.([varname '_' scenario]) = var_data;
    end
end

% Process near-future (2021–2055)
for i = 1:length(scenarios)
    scenario = scenarios{i};
    for k = 1:length(vars)
        varname = vars{k};
        j=2;
        climate = climates{j};
        file_name = ['wheat_corn_soybean_' scenario '_' climate '_2021-2055_timeseries.nc'];
        var_data = ncread(file_name, varname);
        % Average of cooler and hotter
        data_near_hot.([varname '_' scenario]) = var_data;
    end
end










% Process historical data
hist_file = 'wheat_corn_soybean_timeseries_irri_rainfed_timeseries.nc';
for k = 1:length(vars)
    varname = vars{k};
    data_hist.(varname) = ncread(hist_file, varname);
end

% all the above data in % to grid cell area




% Apply region_sum_timeseries and store results
for i = 1:length(scenarios)
    scenario = scenarios{i};
    for k = 1:length(vars)
        varname = vars{k};
        key = [varname '_' scenario];

        % Near-future
        t_data.(['t_' key '_cool']) = region_sum_timeseries(cluster, lat_nc, lon_nc, data_near_cool.(key));

        % Far-future
        t_data.(['t_' key '_hot']) = region_sum_timeseries(cluster, lat_nc, lon_nc, data_near_hot.(key));
    end
end

% Historical data
for k = 1:length(vars)
    varname = vars{k};
    t_data.(['t_' varname '_hist']) = region_sum_timeseries(cluster, lat_nc, lon_nc, data_hist.(varname));
end









conus_area = 52682*12*12; % km2
yr_hist = 1981:2015;
yr_fur_near  = 2021:2055;
% yr_fur_far   = 2061:2095;











%%  include both near and far future; spatial plot

ax1 = subplot(3,3,1)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out = data_hist.corn_nonirri(:,:,end);  out=out'; out(isnan(mask))= nan;

% out = out/(12*12)*100;


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax1, brewermap([],'Greens'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([0 35])
% title('MD to AD Propagation Ratio of Intensity')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
ylabel({'2015 Historical' 'Crop Area', '(% of Cell)'}, 'FontWeight', 'bold');
title('Corn', FontWeight='bold')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(a1)', 'Units', 'normalized', 'FontSize', 11)



ax2 = subplot(3,3,2)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out = data_hist.wheat_nonirri(:,:,end);  out=out'; out(isnan(mask))= nan;

% out = out/(12*12)*100;


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax2, brewermap([],'Greens'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([0 35])
% title('MD to AD Propagation Ratio of Intensity')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
% ylabel({'Wheat Area in 2015', '(% of Grid Cell)'}, 'FontWeight', 'bold');
title('Wheat', FontWeight='bold')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(a2)', 'Units', 'normalized', 'FontSize', 11)




ax3 = subplot(3,3,3)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out = data_hist.soybean_nonirri(:,:,end);  out=out'; out(isnan(mask))= nan;

% out = out/(12*12)*100;


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax3, brewermap([],'Greens'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([0 35])
% title('MD to AD Propagation Ratio of Intensity')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
% ylabel({'Wheat Area in 2015', '(% of Grid Cell)'}, 'FontWeight', 'bold');
title('Soybean', FontWeight='bold')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(a3)', 'Units', 'normalized', 'FontSize', 11)


ax4 = subplot(3,3,4)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out1 = (data_near_cool.corn_nonirri_ssp3_rcp45(:,:,end)+data_near_hot.corn_nonirri_ssp3_rcp45(:,:,end))/2;   out1= out1'; out1(isnan(mask))= nan;

out2 = data_hist.corn_nonirri(:,:,end); out2 = out2'; out2(isnan(mask))= nan;

out = (out1-out2);


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax4, brewermap([],'*RdBu'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([-25  25])
% title('MD to AD Propagation Ratio of Intensity')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
ylabel({'Mean Change in 2055', 'rcp45-ssp3'}, 'FontWeight', 'bold');
% title('SSP345 2055 vs Hist. 2015')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(b1)', 'Units', 'normalized', 'FontSize', 11)


ax5 = subplot(3,3,5)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out1 = (data_near_cool.wheat_nonirri_ssp3_rcp45(:,:,end) + data_near_hot.wheat_nonirri_ssp3_rcp45(:,:,end))/2;   out1= out1'; out1(isnan(mask))= nan;

out2 = data_hist.wheat_nonirri(:,:,end); out2 = out2'; out2(isnan(mask))= nan;

out = (out1-out2);


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax5, brewermap([],'*RdBu'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([-25  25])
% title('MD to AD Propagation Ratio of Intensity')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
% ylabel({'Change in Wheat Area', '(% of Grid Cell)'}, 'FontWeight', 'bold');
% title('SSP345 2055 vs Hist. 2015')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(b2)', 'Units', 'normalized', 'FontSize', 11)




ax6 = subplot(3,3,6)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out1 = (data_near_cool.soybean_nonirri_ssp3_rcp45(:,:,end)+data_near_hot.soybean_nonirri_ssp3_rcp45(:,:,end))/2;   out1= out1'; out1(isnan(mask))= nan;

out2 = data_hist.soybean_nonirri(:,:,end); out2 = out2'; out2(isnan(mask))= nan;

out = (out1-out2);


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax6, brewermap([],'*RdBu'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([-25  25])
% title('MD to AD Propagation Ratio of Intensity')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
% ylabel({'Change in Soybean Area', '(% of Grid Cell)'}, 'FontWeight', 'bold');
% title('SSP345 2055 vs Hist. 2015')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(b3)', 'Units', 'normalized', 'FontSize', 11)





ax7 = subplot(3,3,7)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out1 = (data_near_cool.corn_nonirri_ssp5_rcp85(:,:,end)+data_near_hot.corn_nonirri_ssp5_rcp85(:,:,end))/2;   out1= out1'; out1(isnan(mask))= nan;

out2 = data_hist.corn_nonirri(:,:,end); out2 = out2'; out2(isnan(mask))= nan;

out = (out1-out2);


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax7, brewermap([],'*RdBu'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([-25  25])
% title('SSP585 2055 vs Hist. 2015')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
ylabel({'Mean Change in 2055', 'rcp85-ssp5'}, 'FontWeight', 'bold');
% title('Prob(MD to AD) Diff. (%)')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(c1)', 'Units', 'normalized', 'FontSize', 11)



ax8 = subplot(3,3,8)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out1 = (data_near_cool.wheat_nonirri_ssp5_rcp85(:,:,end)+data_near_hot.wheat_nonirri_ssp5_rcp85(:,:,end))/2;   out1= out1'; out1(isnan(mask))= nan;

out2 = data_hist.wheat_nonirri(:,:,end); out2 = out2'; out2(isnan(mask))= nan;

out = (out1-out2);


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax8, brewermap([],'*RdBu'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([-25  25])
% title('SSP585 2055 vs Hist. 2015')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
% ylabel('Corn Diff. (%)', 'FontWeight', 'bold');
% title('Prob(MD to AD) Diff. (%)')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(c2)', 'Units', 'normalized', 'FontSize', 11)


ax9 = subplot(3,3,9)
hist = load('conus_cell_hist.txt');
index = 3;  
monthly_data = hist(:,index);  % cluster
% monthly_data(monthly_data==0)= nan;
out = nan(224, 464);
for i = 1:length(monthly_data)
    out(row_idx(i), col_idx(i)) = monthly_data(i);
end
mask = out;

out1 = (data_near_cool.soybean_nonirri_ssp5_rcp85(:,:,end)+data_near_hot.soybean_nonirri_ssp5_rcp85(:,:,end))/2;   out1= out1'; out1(isnan(mask))= nan;

out2 = data_hist.soybean_nonirri(:,:,end); out2 = out2'; out2(isnan(mask))= nan;

out = (out1-out2);


pcolor(lon, lat, out); hold on; shading flat;
colormap(ax9, brewermap([],'*RdBu'));           % YlGnBu for frequnecy, and duration, YlOrRd for intensity
caxis([-25  25])
% title('SSP585 2055 vs Hist. 2015')
scatter(us_coor(:,1), us_coor(:,2), 0.5, [192 192 192]/255); hold on
scatter(r1(:,2), r1(:,1), b_line, [0 0 0]); hold on
scatter(r2(:,2), r2(:,1), b_line, [0 0 0]); hold on
scatter(r3(:,2), r3(:,1), b_line, [0 0 0]); hold on
scatter(r4(:,2), r4(:,1), b_line, [0 0 0]); hold on
scatter(r5(:,2), r5(:,1), b_line, [0 0 0]); hold on
scatter(r6(:,2), r6(:,1), b_line, [0 0 0]); hold on
scatter(r7(:,2), r7(:,1), b_line, [0 0 0]); hold on

ylim([25, 50])
% colorbar
% ylabel('Corn Diff. (%)', 'FontWeight', 'bold');
% title('Prob(MD to AD) Diff. (%)')

xt = xticks;
yt = yticks;

% Create labels with degree symbols
xt_labels = arrayfun(@(x) sprintf('%.0f°', x), xt, 'UniformOutput', false);
yt_labels = arrayfun(@(y) sprintf('%.0f°', y), yt, 'UniformOutput', false);

% Apply the new tick labels
xticklabels(xt_labels);
yticklabels(yt_labels);
% text(0.1, 0.1, '(a1)', 'Units', 'normalized')
text(0.1, 0.1, '(c3)', 'Units', 'normalized', 'FontSize', 11)


%% plot the error bar plot

% Assuming t_data is already loaded

% Assuming t_data is already loaded

crops = {'corn', 'wheat', 'soybean'};
x = 1:8;

figure;

i=3
    crop = crops{i};
    
    % Fieldnames
    hist_field = sprintf('t_%s_nonirri_hist', crop);
    ssp3_cool = sprintf('t_%s_nonirri_ssp3_rcp45_cool', crop);
    ssp3_hot  = sprintf('t_%s_nonirri_ssp3_rcp45_hot', crop);
    ssp5_cool = sprintf('t_%s_nonirri_ssp5_rcp85_cool', crop);
    ssp5_hot  = sprintf('t_%s_nonirri_ssp5_rcp85_hot', crop);
    
    % Extract 35th column
    hist_data = t_data.(hist_field)(:,35);
    ssp3_cool_data = t_data.(ssp3_cool)(:,35);
    ssp3_hot_data  = t_data.(ssp3_hot)(:,35);
    ssp5_cool_data = t_data.(ssp5_cool)(:,35);
    ssp5_hot_data  = t_data.(ssp5_hot)(:,35);
    
    % Plot
    subplot(3,1,i); hold on;
    
    % Bar: historical
    bar(x, hist_data, 0.4, 'FaceColor', [0.7 0.7 0.7]);

    % Bar centers (for alignment)
    ssp3_x = x + 0.25;
    ssp5_x = x + 0.5;

    % Plot invisible SSP bars (optional)
    b3 = bar(ssp3_x, (ssp3_hot_data + ssp3_cool_data)/2, 0.2, 'FaceColor', [0.6 0.8 1], 'EdgeColor', 'none');
    b5 = bar(ssp5_x, (ssp5_hot_data + ssp5_cool_data)/2, 0.2, 'FaceColor', [1 0.6 0.6], 'EdgeColor', 'none');

    % Custom error bars (hot/cool as min/max)
    for k = 1:8
        % SSP3
        y1 = min(ssp3_cool_data(k), ssp3_hot_data(k));
        y2 = max(ssp3_cool_data(k), ssp3_hot_data(k));
        line([ssp3_x(k) ssp3_x(k)], [y1 y2], 'Color', 'b', 'LineWidth', 1.5);
        line([ssp3_x(k)-0.05 ssp3_x(k)+0.05], [y1 y1], 'Color', 'b', 'LineWidth', 1); % bottom cap
        line([ssp3_x(k)-0.05 ssp3_x(k)+0.05], [y2 y2], 'Color', 'b', 'LineWidth', 1); % top cap
        
        % SSP5
        y1 = min(ssp5_cool_data(k), ssp5_hot_data(k));
        y2 = max(ssp5_cool_data(k), ssp5_hot_data(k));
        line([ssp5_x(k) ssp5_x(k)], [y1 y2], 'Color', 'r', 'LineWidth', 1.5);
        line([ssp5_x(k)-0.05 ssp5_x(k)+0.05], [y1 y1], 'Color', 'r', 'LineWidth', 1); % bottom cap
        line([ssp5_x(k)-0.05 ssp5_x(k)+0.05], [y2 y2], 'Color', 'r', 'LineWidth', 1); % top cap
    end

    title(upper(crop)); ylabel('Value');
    xlim([0.5 9]); xticks(1:8);
    if i == 3
        xlabel('Index (1 to 8)');
    end
    legend('Hist', 'SSP3-4.5', 'SSP5-8.5', 'Location', 'northwest');


















%% output the plot

fig = gcf;
fig.PaperUnits = 'inches';


fig.PaperPosition = [0 0 10 6];  % 3x3 spatial maps
print('ScreenSizeFigure', '-dpng', '-r300')

