#README


###Outline

This document outlines the work done by the DSSG Health Insurance team for Get Covered Illinois in the summer of 2014. The primary output of the work was a system for scoring television advertisements according to the number of calls and website hits they were likely to generate. 

The main product is both a set of models and a pipeline to transform model outputs into scores for new (yet-to-be-bought) advertisements. These two parts may be modified independently. That is, if an analyst would like to improve the models, they may do so, so long as the output is in the same format. 


## Installing the software and running the program

To run this software, the analyst should install:

- R from http://cran.r-project.org/
- R Studio from http://www.rstudio.com/
- From within R Studio, the following packages should be installed (from Tools --> Install packages):
 - lubridate
 - dplyr
 - zoo
 - reshape2
 - dyn
 - shiny

The required datafiles (outputs of the modelling step) will not be available online, as they contain commercial in confidence data. These  will be provided to GCI. 

Running the application involves simply opening either ui.R or server.R, and pressing "Run App" in the top right hand corner of the script. 

Re-running the modelling files will involve running Master_program.R by selecting all and holding ctrl-A from within R Studio. This will generate a file that is used in the application. 

### The problem

What are we maximising? The state of Illinois spent around $8m on television advertising to encourage uninsured Illinois residents to take out insurance in the Marketplace. This exercise generated a lot of useful data. The State was interested to know if much could be learned about the efficacy of different types of advertising spending. If much could be learned, then the State could better target advertising spending in the coming open enrolment period, saving money and increasing exposure. 

We used data on all ad spot buys over the open enrollment period, and merged these data with call center and websit hit volumes. Unfortunately, the information on ad buys was patchy; some entries identified ad purchases to within the hour, while other entries described ad buys that occured within a certain time-slot for a whole week. Consequently, only about half of the aggregate spend data could be used to assess ad efficacy. 

Because the advertisements could not be placed precisely, we were forced to aggregate expenditure to a daily level. While the observations are at the daily level, we have split out advertising by market, time of day (primetime or not primetime), language and cost bucket. All models are built on these subsets of aggregate expenditure. 


### Findings in the data

#### Model strategy

The modelling methodology is to use a technique known as auto-regressive distributed lag (ARDL) modelling, where the dependent variables&mdash;phone calls and website hits&mdash;have first been detrended by day-of-week effects, a time trend and a squared trend. 

ARDL models are time-series model of the form:

<img src="http://www.sciweavers.org/tex2img.php?eq=%24Y_%7Bt%7D%20%3D%20%5Calpha_%7B0%7D%20%2B%20%5Ctheta_%7B1%7D%20Y_%7Bt-1%7D%20%2B%20%5Cdots%20%2B%20%5Ctheta_%7Bp%7D%20Y_%7Bt-p%7D%20%2B%20%5Cdelta_%7B0%7D%20X_%7Bt%7D%20%2B%20%5Cdots%20%2B%20%5Cdelta_%7Bq%7D%20X_%7Bt-q%7D%20%2B%20%5Cepsilon_%7Bt%7D%24&bc=White&fc=Black&im=jpg&fs=12&ff=arev&edit=0" align="center" border="0" alt="$Y_{t} = \alpha_{0} + \theta_{1} Y_{t-1} + \dots + \theta_{p} Y_{t-p} + \delta_{0} X_{t} + \dots + \delta_{q} X_{t-q} + \epsilon_{t}$" width="460" height="21" />

Which would be called a ARDL (p, q) model. The ARDL family of models have several advantages for this type of modelling: 
- A change in the independent variable X has both immediate impacts on the dependent variable Y, and also delayed impacts. 
- The model can be converted into a so-called Infinite Distributed Lag (IDL) model, where the current value of Y is entirely explained by it's unconditional average and historical values of X. These models take the form:
 
<img src="http://www.sciweavers.org/tex2img.php?eq=%24Y_%7Bt%7D%20%3D%20%5Cbeta_%7B0%7D%20%2B%20%5Cbeta_%7B1%7D%20X_%7Bt%7D%20%2B%20%5Cbeta_%7B2%7D%20X_%7Bt-1%7D%20%2B%20%5Cdots%20%2B%20%5Cnu_%7Bt%7D%24&bc=White&fc=Black&im=jpg&fs=12&ff=arev&edit=0" align="center" border="0" alt="$Y_{t} = \beta_{0} + \beta_{1} X_{t} + \beta_{2} X_{t-1} + \dots + \nu_{t}$" width="274" height="19" />.

Details of how to transform the parameters in the ARDL model (thetas and deltas) into the parameters in an IDL model (betas) are given in section 9.8 of Principles of Econometrics (4e), by Hill, Griffiths and Lim. 

The strategy to estimate the impacts of a given type of advertising is to do the following: 

- Firstly remove the time-trend in both phone calls and web hits by regressing log phone calls (web hits) on a time trend and squared time trend, as well as day-of-the-week effects. 
- The residuals from this first equation are approximately the percentage deviations from average daily calls/web hits; this is what we want to describe using an ARDL model. 
- Estimate an ARDL(1,1) model, where the dependent variable (Y) is the residuals from the step above, and the independent variable X is the log of the type of advertising expenditure we are examining. 
- Convert the estimated coefficients (δ and θ) into IDL form. This allows us to examine the impact of advertising on calls/web hits *over time*. 

Once we have estimates of the β in the IDL model above, we can examine the impact of a unit increase in advertising over time; it is simply the sum of the βs. Beyond a dozen or so lags, most of the βs are very close to 0, indicating that the impact of the ad has wasted away. As the regression model is in log-log form, the sum of the βs is interpretable as being approximately the percentage increase in phone calls/web hits from a 1 per cent increase in advertising spend. 

#### Concerns with the model

Ideally, we want the estimated coefficients on the X values in the model (δ) to be equal to the true causal impact of advertising spending on call volumes/web hits. This is difficult to establish, for two reasons. The first is the well-known *correlation is not causation*. Just because calls/web hits increase after advertising, this does not mean advertising caused the outcomes. In general, the relationship we estimate will typically be the average amount the two variables X and Y move together. The second reason is that a lot of other things are changing at the same time (like other advertising forms), which may drive calls/web hits but which increase at the same time as X. The more that two different types of advertising move together (say, advertising in Rockford and advertising in Springfield), the more difficult it is to attribute a change in the outcome variable to one of these independently. 

These concerns are somewhat insurmountable, though we've tried ameliorating them by the following adjustments: 
- Use the data over the shut-down period in late January; this establishes a very weak experiment. This should reduce the bias in the estimate of the response of calls/web hits to advertising *on aggregate*. However, it does not reduce the problem caused by correlation among the different categories of advertising.
- Pre-processing the dataset to remove the effect of aggregate advertising spend, a time-trend, and day-of-the-week effects. This goes a small way to reducing the effect of individual advertising categories moving together. 

Due to the fairly short time-period over which the advertisements ran, including many (fairly correlated) contol variables (advertising categories other than the one we're examining) results in extremely wide confidence intervals, and little useful insight. On the other hand, excluding them is likely to make the estimates of the impact of a given advertising category be higher than the real effect. 

To get around this problem, the model effectively ranks advertising categories relative to one another. As a heuristic, ad types that tended to be effective should show up as being high-value using the approach. 

#### Converting model output into scores

Once we have estimates of the βs, we need to make a few adjustments to turn these into an estimate of the uplift in calls/website hits that each advertisement would be expected to bring. 

1. As the sums of the βs are approximately equal to the percentage increase in web-hits/calls from a 1 per cent increase in X (the advertising spend), we need to find what 1 dollar of X is as a percentage of X. We can then work out the impact of a 1 dollar increase in X is on calls/web hits over time. 
2. To get an estimate of the uncertainty over this impact, we use bootstrapping, whereby the model is estimated many times, on data randomly drawn from actual observations (with replacement). This is a common method of quantifying uncertainty. 
3. We then have a predicted uplift for each category of advertising spending. The problem is now that a given advertisement belongs to several categories; it may be in Paducah, in Spanish, during prime-time, and at a given cost. What's more, we can't estimate the impact of these types of advertisement alone, as we have insufficient data. These individual ad categories may have different uplift scores, so how should we convert them to an expected uplift? The fairly hackish way of getting around this was to weight the outputs of the different models, according to how much each model represents the ad. 
4. We can do this for all the strata (city, language, time of day, cost combination) for which we have observations. As a precaution, we can take a pessimistic view about the efficacy of each ad category, by taking the i-th percentile of each prediction. That way, estimates that are highly uncertain will tend to be closer to 0. 

This is the output of the modelling process. Essentially, it is all the strata for which we have observations, along with the predicted uplift per dollar spent of advertising on web hits and phone calls. 

When we have a new set of advertisements that we could possibly purchase, we simply generate the appropriate strata for each advertisement, and merge the modelling output with the ad manifest. Given the value we can attach to a phone call or website hit, we can give a numeric value to each advertisement, and evaluate whether we consider that an advertisement would add value or not. We can then rank advertisements according to how much value they should provide. 


#### Next steps with the model

There are several improvements that should be made to the modelling approach: 

- The current approach does not take account of new information in any sensible way. The first big change would be to go to a Bayesian model. This requires a bit of work, but means that as new information comes to bear next enrolment period, the model would incorporate this information coherently. 
- Regardless of whether we go to a Bayesian model, the model needs to treat control variables better. This requires further research. 
- The various models should be combined in a more coherent way.
- The models could benefit from the inclusion of experimental data, as well as regional demographics and uninsuredness. Television ratings were also not taken into account. 

Jim Savage would like to continue improving this model for GCI, to include these changes. This would be a great way of developing a useful commercial framework for assessing advertising effectiveness. 



