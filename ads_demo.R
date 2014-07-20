# Quick demonstration of ad spend effectiveness using vars


# Data construction

# Generate an ad-spend series and a website visits series


website.visits <- NULL

# The first two observations of website.visits
website.visits[1] <- 200
website.visits[2] <- 203

# The first two observations of ads
ads[1] <- 50
ads[2] <- 53

# The data generating process that determines ad buys and website visits
# Notice that in this setup, the ad-buys are dynamically influenced by the website visits. 
for(i in 3:500){
	website.visits[i] <- round(150 + 0.4*ads[i-2] + 0.3*ads[i-1] + 0.6*website.visits[i-1] + 0.2*website.visits[i-2] + rnorm(1, 0, 30))
	website.visits[i] <- ifelse(website.visits[i]>0, website.visits[i], 0)
	ads[i] <- 30 + 0.3*ads[i-1] + 0.05*ads[i-2] + 0.04*website.visits[i-1] + rnorm(1, 0, 3)
	ads[i] <- ifelse(ads[i]>0, ads[i], 0)
}

Y <- cbind(website.visits, ads)

# Have a look at the data
plot.ts(Y)

#Let's say you have some VAR process (we'll leave exogenous variables out for the moment), with some vector Y of K endogenous variables. 

#Y(t) = A0 + A1*Y(t-1) +... + Ap*Y(t-p) + E

#And you want to estimate the As. Well, that's 

library(vars) 

# First, select the number of lags based on information criteria

VARselect(Y, lag.max = 12, type = "const") # const includes the A0 term

# Under this setup, the AIC is minimised at 2. We can now fit an unrestricted vector autoregression with p = 2.

mod.1 <- VAR(Y, type = "const", p = 2)

# We may want to use this to forecast (a bit more tricky if you're using exogenous variables, which you'll need to provide forecasts of):

fanchart(predict(mod.1, n.ahead = 12))

# Zoom in on the end bit

fcst <- predict(mod.1, n.ahead = 12)
fcst$endog <- fcst$endog[((nrow(fcst$endog)-25):nrow(fcst$endog)),]

fanchart(fcst)

# Or inferential "impulse responses"

irf.mod.1 <- irf(mod.1, n.ahead = 12, impulse = "ads", response = "website.visits")

plot(irf.mod.1)
# This tells us what we should expect to website visits (the response) over time with an impulse to ad buys (the impulse). The red lines are bootstrapped 95% confidence intervals

# Well, that was easy. 