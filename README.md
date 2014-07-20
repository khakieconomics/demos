Using a vector autoregression to work out the impact of advertising spend
=====

The script in this repo gives a simple demonstration of how one could do some analysis of advertising expenditure using a vector autoregression model. The model is fairly general, but makes the following asumptions:
- Both ad placements and website traffic are mutually endogenous
- There are no trends or unit roots. If your data do have trends and/or unit roots, look at library(urca) and the VECM function in vars.
- I have not included any exogenous regressors. In general, you would have day of the week effects, time of day effects, etc. You can include a matrix of these in the call to VARS. You'll want to drop the intercept term "const" if you have these effects (colinearity). 
- **The most important thing** is that it assumes that your treatment is conditionally exogenous. That is, you are trying to estimate the *causal* impact of advertising expenditure on website traffic. If you don't have a conditionally exogenous treatment, then you are only looking at average comovements, which mean a whole bunch less.


