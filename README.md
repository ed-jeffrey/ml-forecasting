# ml-forecasting
This repository is for a machine learning project to forecast carbon intensity in the UK electricity grid. 

## Introduction
Carbon intensity measures how much CO2 is emitted per unit of electricity consumed (gCO2/kWh). It varies throughout the day and year depending on how much renewable energy is available versus fossil fuel generation. Accurate 24-hour forecasts of carbon intensity can help consumers and systems shift demand to lower-carbon periods.

This project trains an XGBoost model to forecast carbon intensity up to 24 hours ahead at 30-minute resolution, using day-ahead demand and renewable generation forecasts from the National Energy System Operator (NESO).

## Data
* The provided dataset is from NESO, covering **2022-01-01 to 2023-01-01** at 30-minute intervals (~17,500 rows).
* The dataset has 7 columns:
- 'from' - a datetime for the 30-minute time window after the quoted datetime

#### GROUND TRUTH
- 'carbon_intensity_actual' - the reported carbon intensity for this 30-minute window in gCO2/kWh

#### FORECASTS
- 'carbon_intensity_forecast' - the forecasted carbon intensity in gCO2/kWh (only to be used for model output comparison)
- 'demand' - the day-ahead (24hr out) demand forecast on the energy grid for this 30-minute window (how much energy is necessary to meet the countries energy needs) in MW
- 'Solar' - the day-ahead (24hr out) forecast of solar energy production in meeting the demand in this 30-minute window in MW
- 'Wind Offshore' - the day-ahead (24hr out) forecast for offshore wind energy production in meeting the demand in this 30-minute window in MW
- 'Wind Onshore' - the day-ahead (24hr out) forecast for onshore wind energy production in meeting the demand in this 30-minute window in MW

Data sources:
- [1-Day Ahead Demand Forecast](https://www.neso.energy/data-portal/1-day-ahead-demand-forecast)
- [Wind and Solar Forecasts](https://www.neso.energy/data-portal/embedded-wind-and-solar-forecasts/embedded_solar_and_wind_forecast)
- [Day Ahead Wind Forecast](https://www.neso.energy/data-portal/day-ahead-wind-forecast/day_ahead_wind_forecast)
- [Carbon Intensity API](https://carbonintensity.org.uk/)


# Methodology
* We train an XGBoost multi-output regressor to predict all 48 half-hour steps of a 24-hour carbon intensity forecast in a single model iteration.

* We apply pre-processing to the dataset to extract additional features that the model needs to learn short, medium and long term trends in the past (hour,multi-day,week) and trends from the forecast (hours ahead):
- Cyclical time features (hour, day of week, month, day of year) as sine/cosine pairs
- One-hot encodings for day and month
- Statistics (mean, std, min, max) of past carbon intensity, demand, and renewable generation at multiple time spans (1hr to 7 days)
- Lag and difference features for the same columns
- Day-ahead forecasts of demand, solar, and wind at each of the steps in the 24-hour forecast (the only future information available at T=0)
- Derived features: renewable percentage, residual demand (~ generation from fossil fuel sources), ramp rates

* We use a typical 80/20 split for training/test subsets. The training data covers January–October 2022 and testing covers October–December 2022. Confining to one period at the end of the year isn't ideal because you cannot evaluate the accuracy of the model during different seasons and conditions, but we did not want to risk data leak or increased data drop due to ovelapping past/future features (rolling means, etc.).
* We also drop any rows with NaNs in any column - this is particularly high (13.4%) as we have rolling averages for past data, and the dataset has periods with NaNs. 

# Installation & Running
The author is running the repo locally in a Poetry environment on VS Code.

```bash
# Install dependencies
make bootstrap
```

# Repo Structure

```
ml-forecasting/
├── data/
│   ├── carbon_intensity_demand_solar_wind_2022-01-01_2023-01-01.csv
│   └── outputs
│       ├── figures/
│       └── model/
├── data_exploration.ipynb   # Initial exploration of dataset
├── model_training.ipynb     # Model training
└── model_evaluation.ipynb   # Model evaluation
```


# Carbon Intensity Calculation Background
The GB carbon intensity 𝐶𝑡 at time 𝑡 is found by weighting the carbon intensity 𝑐𝑔 for fuel type 𝑔 by the generation 𝑃𝑔,𝑡 of that fuel type. This is then divided by national demand 𝐷𝑡 to give the carbon intensity for GB (https://carbonintensity.org.uk/). Here, we are using a dataset with only solar and wind sources.

Fuel Type Carbon Intensity (gCO2/kWh)
Biomass: 120
Coal: 937
Gas (Combined Cycle): 394
Gas (Open Cycle): 651
Hydro: 0
Nuclear: 0
Oil: 935
Other: 300
Solar: 0
Wind: 0
Pumped Storage: 0
French Imports ~ 53
Dutch Imports ~ 474
Belgium Imports ~ 179
Irish Imports ~ 458
(https://carbonintensity.org.uk/)

# Notes on Output and Model Performance

| Metric | XGBoost Model | National Grid |
|--------|--------------|---------------|
| MAE    | 17.054       | 10.837        |
| MSE    | 505.841      | 233.470       |
| RMSE   | 21.959       | 15.280        |
| MAPE   | 11.500%      | 7.900%        |
| R²     | 0.869        | 0.952         |

* Our model has a higher MAE, MSE, RMSE, MAPE and lower R² compared to the National Grid model and this was expected.
* The provided dataset only had forecasted demand, wind and solar. This limits the models ability in a few ways:
- There is a wealth of actual and forecasted data from NESO for the different fuel types listed above, such as nuclear, oil, etc which is missing from our training data. For our purposes, we approximated the residual demand as non-renewable energy sources however this introduces uncertainty into the model. This approximate non-renewable amount can be innacurate if nuclear energy production increases and covers a percentage of the demand -> and this wouldn't be captured in our "residual demand" figure. At the moment, this would be accounted for as a "non-renewable" source. 
- In addition to this, NESO most likely uses real (actual) past data for forecasting, whilst we only have day-off forecasts for past data. This introduces uncertainty because the day-off forecasts are not ground truth and are inherently erroneous.
* The way we are handling NaNs can be improved, dropping ~13% of the training data is not ideal.
* The author ran out of time to properly conduct hyperparameter tuning for the model training.
* There was a lot more the author wanted to do for data exploration, model output analysis, but unfortunately ran out of time!
