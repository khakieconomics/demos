

library(Quandl); library(zoo); library(randomForest); library(ggplot2); library(reshape2)

# Data downloading
nad <- Quandl("JAVAGE/58N", collapse = "quarterly", type = "zoo")
head(nad1)
naddf <- as.data.frame(nad)

# Renaming
names(naddf) <- c("Prod", "UR", "dInventories", "GFCF", "GDPZ", "HSR", "GDP", "RTWI")

nad1 <- naddf[complete.cases(naddf),]

# Data adjustments
nad1 <- within(nad1, {
	PGDP <- GDPZ/GDP
	dPGDP <- c(NA, diff(log(PGDP)))
	dGDP <- c(NA, diff(log(GDP)))
	dINV <- c(NA, diff(log(GFCF)))
	dUnemp <- c(NA, diff(UR))
	GDPZ <- NULL
	GDP <- NULL
	PGDP <- NULL
})

# Create model matrix
nad1 <- as.zoo(nad1, order.by = row.names(nad1))
nad1 <- nad1[complete.cases(nad1),]
nad2 <- merge(nad1, lag(nad1, -1), lag(nad1, -2))
nad2 <- nad2[complete.cases(nad2),]

# Get illegal chrs out of names
names(nad2) <- gsub(pattern = "[-| |'('|')'|,]", replacement = "", names(nad2), perl = TRUE)

data.frame(names(nad2), 1:30)
# Let's say we want to build a model that predicts the impact of unemployment on productivity. This is only illustrative of the technique, and such a relationship is not identified, as I'm making no claim about the exogeniety of unemployment.

# Now, let's build a bunch of models, starting in about 2002, using all the data to that stage. This happens in a loop. 

# Prepare the output data frame
out <- data.frame(Dates = index(nad2)[100:length(index(nad2))], coef.estimate = NA, se.coef = NA)
row.names(out) <- out$Dates
out$Dates <- as.POSIXct(as.yearqtr(out$Dates))

for(i in index(nad2)[100:length(index(nad2))]){
	
	# Subset the data up to the ith date
	dta.ss <- window(nad2, start = "1979 Q3", end = i)
	
	# Run the random forest model predicting changes to productivity, making sure to save the proximity matrix
	rf1 <- randomForest(Prod.nad1 ~ ., data = dta.ss, ntree = 1000, do.trace = TRUE, proximity = TRUE)
	
	# Drop lagged unemployment changes (don't want the dynamic impact)
	dta.ss <- subset(dta.ss, select = c(-27, -17))
	
	# Simple linear model
	mod1 <- lm(Prod.nad1 ~ ., data = dta.ss, weights = rf1$proximity[i,])
	# place the coefficient estimate and standard error into the output data frame
	out[i,2] <- coef(mod1)[2]
	out[i,3] <- summary(mod1)$coefficients[2,2]
	
	
}


# Plot the time-varying coefficient estimates

# Run a model for the regression we would run today with no weighting (full dataset)
lm2 <- lm(Prod.nad1 ~ ., data = dta.ss)

# Plot the time-varying coefficient and the coeffient we'd estimate today

# note that while we would today estimate the effect as 0, there are periods in which the effect appears quite large. These appear to be right after the slowdowns. 

ggplot(out, aes(x= Dates, group = 1)) + geom_ribbon(aes(ymin = coef.estimate - 1.96*se.coef, ymax = coef.estimate + 1.96*se.coef), fill = "grey", alphe = 0.3)+geom_line(aes(y = coef.estimate)) + scale_x_datetime() + xlab("Time model estimated") + ylab("Estimate of linear relationship\nbetween d(unemployment) and productivity growth") + ggtitle("The relationship between variables\ncan change when we look only at similar histories\n") + geom_hline(aes(y = coef(lm2)[2]))


# How do the weights look? As in, how much of the data are we actually using?

# Get the model fitted values, residuals, and the residuals of the unweighted regression

out2 <- data.frame(predicted = mod1$fitted.values, residuals = mod1$residuals, improvement = lm2$residuals, weights = rf1$proximity[i,])
# Data construction
out2$actual <- with(out2, predicted + residuals)
out2$Date <- as.POSIXct(as.yearqtr(row.names(out2)))

# Reordering
out2 <- out2[,c(5,1,2,3,4,6)]
out2$improvement <- out2$improvement - out2$residuals
out2.m <- melt(out2, id = c("Date", "weights"))

# Plotting
ggplot(out2.m, aes(x = Date, y = value, fill = weights)) + geom_bar(stat = "identity") + facet_grid(variable~., scale = "free") + scale_fill_gradient(low = "white", high = "black") + theme_bw(base_size = 22) + ggtitle("Proximity weighting relevant histories\n")

# now let's have a look at 

rf1$proximity[1:5, 1:5]
