%% Load database
data = readtable('CoralHydro2k_Seawater_1_0_0.csv');

data.Properties.VariableNames = strrep(data.Properties.VariableNames, ' ', '_');
data.Properties.VariableNames(11) = "Latitude_decimal_degrees_N";
data.Properties.VariableNames(12) = "Longitude_decimal_degrees_E";
%% Filter to Upper 5m, Tropical Pacific
% Change longitudes to [0, 360]
data.Longitude_decimal_degrees_E(data.Longitude_decimal_degrees_E < 0) = ...
    data.Longitude_decimal_degrees_E(data.Longitude_decimal_degrees_E < 0) + 360;
% Filter based on columns
surface = data.Depth <= 5;
lat_bounds = data.Latitude_decimal_degrees_N >= -30 & data.Latitude_decimal_degrees_N <= 30;
lon_bounds = data.Longitude_decimal_degrees_E >= 110 & data.Longitude_decimal_degrees_E <= 290;
data_TS = data(surface & lat_bounds & lon_bounds, :);

%% Create date column from Year & Month columns
valid_dates = ~isnan(data_TS.CollectionYear) & ~isnan(data_TS.CollectionMonth);
data_TS = data_TS(valid_dates, :);
data_TS.MonthlyDate = datetime(data_TS.CollectionYear, data_TS.CollectionMonth, 1);

%% Count Monthly coverage of data by region (1990-2025)
startDate = datetime(1995,1,1);
endDate = datetime(2025,12,31);

data_TS2 = data_TS(data_TS.MonthlyDate >= startDate & data_TS.MonthlyDate <= endDate, :);
data_TS2.Lat_bin = floor(data_TS2.Lat);
data_TS2.Lon_bin = floor(data_TS2.Lon);

% Bin observations by month 
month_bins = (startDate:calmonths(1):endDate)';
N = numel(month_bins);

count_west = zeros(N,1);
count_center = zeros(N,1);
count_east = zeros(N,1);

for i = 1:N
    mdata = data_TS2(data_TS2.MonthlyDate == month_bins(i), :);
    if isempty(mdata), continue; end

    sel = mdata.Lon_bin>=110 & mdata.Lon_bin<160;
    if any(sel), count_west(i) = height(unique([mdata.Lat_bin(sel), mdata.Lon_bin(sel)],'rows')); end
    
    sel = mdata.Lon_bin>=160 & mdata.Lon_bin<220;
    if any(sel), count_center(i) = height(unique([mdata.Lat_bin(sel), mdata.Lon_bin(sel)],'rows')); end
    
    sel = mdata.Lon_bin>=220 & mdata.Lon_bin<=290;
    if any(sel), count_east(i) = height(unique([mdata.Lat_bin(sel), mdata.Lon_bin(sel)],'rows')); end
end

counts_TS = [count_west, count_center, count_east];

%% Make Coverage Time Series Plot
figure; 

% Stacked plot
hA = area(month_bins, counts_TS);
hold on;

hA(1).FaceColor = [0.7 0.2 0.2];
hA(2).FaceColor = [0.2 0.5 0.2];
hA(3).FaceColor = [0.2 0.4 0.8];

xlabel('Time');
ylabel('# of observations');

xlim([startDate endDate]);

legend({'Western Pacific','Central Pacific','Eastern Pacific'}, ...
       'Location','northwest');

