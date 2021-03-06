# Required Packages
library(doParallel)
library(plotly)
library(corrplot)
library(caret)
library(dplyr)

# Finding how many cores are on my machine
detectCores() # Result = Typically 4 to 6

# Create Cluster
cl <- makeCluster(2)

# Register Cluster
registerDoParallel(cl)

# Confirm how many cores are now "assigned" to R and RStudio
getDoParWorkers() # Result 2 

# Stop Cluster.
# stopCluster(cl)



# iphone
iphone_df <- iphone_smallmatrix_labeled_8d
summary(iphone_df)
str(iphone_df)

# plotting and understanding the data 
df <- iphone_df
plot_ly(df, x= ~df$iphonesentiment, type='histogram')

# Checking for missing data
sum(is.na(df))

################################################ Pre processing the training datatset ##################################################################

# Identifying collinear variables
corrData <- cor(df)
corrplot(corrData)
ncol(df)
s <- findCorrelation(corrData, cutoff = 0.9, verbose = FALSE, names = FALSE, exact = ncol(corrData))
options(max.print=1000000)

# Removing Collinear variables
df[c(29,24,56,34,21,31,51,46,16,57,55,6,5)] <- NULL

# Testing Collinearity:
ncol(df)
corrData <- cor(df)
findCorrelation(corrData, cutoff = 0.9, verbose = FALSE, names = FALSE, exact = ncol(corrData))

# Removing near zero vars:
nzvMetrics <- nearZeroVar(df, saveMetrics = TRUE)
str(nzvMetrics)

# nearZeroVar() with saveMetrics = FALSE returns an vector 
nzv <- nearZeroVar(df, saveMetrics = FALSE) 
str(nzv)

# create a new data set and remove near zero variance features
df_clean <- df[,-nzv]
str(df_clean)

################################################ Sampling the training datatset & setting up RFE ##################################################################

# Sample the data before using Recursive Feature Elimination(RFE)
set.seed(123)
iphoneSample <- df_clean[sample(1:nrow(df_clean), 1000, replace=FALSE),]
nrow(iphoneSample)

# Set up rfeControl with randomforest, repeated cross validation and no updates
ctrl <- rfeControl(functions = rfFuncs, method = "repeatedcv", repeats = 5, verbose = FALSE)
ncol(df_clean)

# Using rfe and omitting the response variable (attribute 59 iphonesentiment) 
rfeResults <- rfe(iphoneSample[,1:11], iphoneSample$iphonesentiment,sizes=(1:11), rfeControl=ctrl)

rfeResults

# Plot results
plot(rfeResults, type=c("g", "o"))

# create new data set with rfe recommended features
iphoneRFE <- df_clean[,predictors(rfeResults)]
str(iphoneRFE)

# add the dependent variable to iphoneRFE
iphoneRFE$iphonesentiment <- df_clean$iphonesentiment
df$iphonesentiment <- as.factor(df$iphonesentiment)
# review outcome
str(iphoneRFE)

dataPar <- createDataPartition(df$iphonesentiment, p = .70, list = FALSE)
train_df <- df[dataPar,]
test_df <- df[-dataPar,]
str(df)

################################################ cross validation & Modeling ################################################

# cross validation 
fitControl <- trainControl(method = "repeatedcv", number = 10, repeats = 1)

##### Decision Tree (C5.0) #####
system.time(dt_c50 <- train(iphonesentiment~., data = df, method = 'C5.0', trControl=fitControl)) # X 

##### Random Forest  #####
system.time(rf <- train(iphonesentiment~., data = df, method = 'rf', trControl = fitControl ))

##### Support Vector Machine #####
# SVM (from the e1071 package) 
library(e1071)
model_svm <- svm(iphonesentiment ~., data = df)
psvm <- predict(model_svm, test_df) 
postResample(psvm, test_df$iphonesentiment)

# K-nearest Neighbors (from the kknn package)
library(kknn)
knn1 <- train.kknn(iphonesentiment ~ ., data = df)#, kmax = 15)
pknn <- predict(knn1, test_df) 
postResample(pknn, test_df$iphonesentiment)

# Creating confusion matrix
cm_dt <- confusionMatrix(pdt, test_df$iphonesentiment) 
cmRF

cmRF <- confusionMatrix(prf, test_df$iphonesentiment) 
cmRF

cmsvm <- confusionMatrix(psvm, test_df$iphonesentiment) 
cmsvm

cmknn <- confusionMatrix(pknn, test_df$iphonesentiment) 
cmknn

# Grouped bar chart to evaluate model performance
Eval <- c(post_c50, post_rf, post_svm, post_knn)
barplot(Eval, main = "Model Evaluation", col = c("darkblue","red"))

rft
dt_c50
model_svm
knn1
m_svm

################################################ Pre processing the validation/prediction datatset ##################################################################

large_df <- iphoneLargeMatrix
str(iphoneLargeMatrix)
large_df$id <- NULL
large_df[c(29,24,56,34,21,31,51,46,16,57,55,6,5)] <- NULL

################################################ Apply Model on the large dataset ################################################ 
large_df$iphonesentiment<- predict(rft, iphoneLargeMatrix)
head(large_df$iphonesentiment, 5)
summary(large_df$iphonesentiment)

