lcdf <- read.csv("lcData100K.csv")
library('tidyverse')
library('lubridate')
library('rpart')
library('dplyr')
library('knitr')
library('ggplot2')
library(pacman)
library(tidyr)
glimpse(lcdf)
summary(lcdf)

##Question 2I
##Proportion of Defaults
lcdf %>% group_by(loan_status) %>% tally() %>% mutate(percent=n/sum(n)*100)
##Proportion of Defaults at grade level
lcdf %>% group_by(grade,loan_status) %>% tally() %>% mutate(percent=n/sum(n)*100)
##Proportion of Default/Fully Paid at grade/subgrade level
Q2i<- lcdf %>% group_by(grade,sub_grade,loan_status) %>% tally() %>% mutate(percent=n/sum(n)*100)
View(Q2i)
##Default rate increases as the grade level decreases (A to G). This relationship is consistent
##with sub grade too.  This makes sense since the grade is related to overall risk of the loan. Riskier loans are
##associated with higher rates of default

##Question 2II
##Number of Loans in each grade
lcdf %>% group_by(grade) %>% tally() %>% mutate(percent=n/sum(n)*100)
##Loan amounts (Total, avg, stdev, min, max) by loan grade
lcdf %>% group_by(grade) %>% summarize(TotalLoanAmt=sum(funded_amnt),AvgLoanAmt=mean(funded_amnt),stdevLoanAmt=sd(funded_amnt),MinLoanAmt=min(funded_amnt),MaxLoanAmt=max(funded_amnt))
##Loan amounts (Total, avg, stdev, min, max) by loan grade and sub grade
Q2ii_Amount<-lcdf %>% group_by(grade,sub_grade) %>% summarize(TotalLoanAmt=sum(funded_amnt),AvgLoanAmt=mean(funded_amnt),stdevLoanAmt=sd(funded_amnt),MinLoanAmt=min(funded_amnt),MaxLoanAmt=max(funded_amnt))
View(Q2ii_Amount)
##interest rates (avg, stdev, min,max) by loan grade
lcdf %>% group_by(grade) %>% summarize(Avginterestrate=mean(int_rate),stdevinterest=sd(int_rate),Mininterstrate=min(int_rate),Maxinterestrate=max(int_rate))
##interest rates (avg, stde, min, max) by loan grade and sub grade
Q2ii_Interestrate <-lcdf %>% group_by(grade, sub_grade) %>% summarize(Avginterestrate=mean(int_rate),stdevinterest=sd(int_rate),Mininterstrate=min(int_rate),Maxinterestrate=max(int_rate))
View(Q2ii_Interestrate)
##Generally the amount funded decreases as loan grade gets worse and interest rates increase as
##loan grades/sub-grades get worse. Stdev in interest rates and funded amount increases as the loan grades get worse
##This is consistent with what woudl be expected since higher risk loans need to have a higher potential return to the investor.  Therefore there would be more support for investors to 
##invest in less risky loans, and those that are risky shoudl have a higher interest rate.  

##Question2III
lcdf$annRet <- ((lcdf$total_pymnt -lcdf$funded_amnt)/lcdf$funded_amnt)*(12/36)*100
head(lcdf[, c("last_pymnt_d", "issue_d")])
lcdf$last_pymnt_d<-paste(sep = "",lcdf$last_pymnt_d, "-01")
head(lcdf[, c("last_pymnt_d", "issue_d")])
lcdf$last_pymnt_d<-parse_date_time(lcdf$last_pymnt_d,"myd")
head(lcdf[, c("last_pymnt_d", "issue_d")])
lcdf$actualTerm <- ifelse(lcdf$loan_status=="Fully Paid", as.duration(lcdf$issue_d  %--% lcdf$last_pymnt_d)/dyears(1), 3)
lcdf$actualReturn <- ifelse(lcdf$actualTerm>0, ((lcdf$total_pymnt -lcdf$funded_amnt)/lcdf$funded_amnt)*(1/lcdf$actualTerm)*100, 0)
lcdf %>% select(loan_status, int_rate, funded_amnt, total_pymnt, annRet, actualTerm, actualReturn) %>%  head()
boxplot(lcdf$actualTerm~lcdf$grade, data=lcdf, xlab("Loan Grade"), ylab("ActualTerm"))
lcdf%>%group_by(grade)%>%summarize(AvgTerm=mean(lcdf$actualTerm), MinTerm=min(lcdf$actualTerm), MaxTerm=max(lcdf$actualTerm))
summary(lcdf$actualTerm)

##Question2IV
lcdf %>% group_by(sub_grade, loan_status) %>% summarise(nLoans=n(), avgIntRate=mean(int_rate),  avgLoanAmt=mean(loan_amnt),  avgActRet = mean(actualReturn), avgActTerm=mean(actualTerm))
View(Q2Iv <-lcdf %>% group_by(sub_grade, loan_status) %>% summarise(nLoans=n(), avgIntRate=mean(int_rate),  avgLoanAmt=mean(loan_amnt),  avgActRet = mean(actualReturn), avgActTerm=mean(actualTerm)))

##Question2V
lcdf %>% group_by(purpose) %>% summarise(nLoans=n(), defaults=sum(loan_status=="Charged Off"), defaultRate=defaults/nLoans, avgLoanAmt=mean(loan_amnt))
table(lcdf$purpose, lcdf$grade)

##Question2VI
lcdf %>% group_by(emp_length) %>% summarise(nLoans=n(), defaults=sum(loan_status=="Charged Off"), defaultRate=defaults/nLoans, avgIntRate=mean(int_rate), avgLoanAmt=mean(loan_amnt), avgActRet=mean(actualReturn),avgActTerm=mean(actualTerm))
lcdf$emp_length <- factor(lcdf$emp_length, levels=c("n/a", "< 1 year","1 year","2 years", "3 years" ,  "4 years",   "5 years",   "6 years",   "7 years" ,  "8 years", "9 years", "10+ years" ))
lcdf %>% group_by(emp_length) %>% summarise(nLoans=n(), defaults=sum(loan_status=="Charged Off"), defaultRate=defaults/nLoans, avgIntRate=mean(int_rate), avgLoanAmt=mean(loan_amnt), avgActRet=mean(actualReturn),avgActTerm=mean(actualTerm))
lcdf %>% group_by(loan_status) %>% summarise(AnnualIncome=mean(annual_inc))

##Question2VII
#New Variable - DTI after loan origination
Monthly_Income <-lcdf$annual_inc/12
Monthly_Debt_Beforeloan <- Monthly_Income*lcdf$dti
lcdf$DTI_AfterLoan <- round(((Monthly_Debt_Beforeloan+lcdf$installment)/Monthly_Income),2)
Q2VIIA <- lcdf %>% select(c(DTI_AfterLoan,grade,loan_status))
Q2VIIA %>% group_by(grade,loan_status) %>% summarize(AvgDTI_AfterLoan=mean(DTI_AfterLoan),MedianDTI_AfterLoan=median(DTI_AfterLoan),stdev=sd(DTI_AfterLoan), Min=min(DTI_AfterLoan), Max=max(DTI_AfterLoan))
summary(lcdf$DTI_AfterLoan)
boxplot(lcdf$DTI_AfterLoan~lcdf$grade,lcdf,ylab=("DTI After Loan"),xlab = "Loan Grade")

#New Variable - Expected Interest as Percent of Annual Income
expected_interest <- lcdf$installment*36-lcdf$loan_amnt
lcdf$expint_perincome <-round(((expected_interest/lcdf$annual_inc)*100),2)
lcdf %>% group_by(grade,loan_status) %>% summarize(AVGexpint_perincome=mean(expint_perincome),Medianexpint_perincome=median(expint_perincome),stdev=sd(expint_perincome),Min=min(expint_perincome),Max=max(expint_perincome))
boxplot(lcdf$expint_perincome~lcdf$grade,lcdf,ylab = ("Expected Interest Per Income"),xlab = ("Loan Grade"))
View(filter(lcdf, lcdf$expint_perincome<0))
##New Variable - Percent of accounts still open
lcdf$per_accounts_open <-round((lcdf$open_acc/lcdf$total_acc)*100,2)
lcdf %>% group_by(grade,loan_status) %>% summarize(AVGPercentOpenAcc=mean(per_accounts_open),MedianPercentOpenAcc=median(per_accounts_open),stdev=sd(per_accounts_open),Min=min(per_accounts_open),Max=max(per_accounts_open))
boxplot(lcdf$per_accounts_open~lcdf$grade,lcdf,ylab = ("Percent of Accounts Open"), xlab = ("Loan Grade"))

##Question 2C - Missing Values
lcdf <- lcdf %>% select_if(function(x){!all(is.na(x))})
names(lcdf)[colSums(is.na(lcdf))>0]
colMeans(is.na(lcdf))
colMeans(is.na(lcdf))[colMeans(is.na(lcdf))>0]
nm<-names(lcdf)[colMeans(is.na(lcdf))>0.6]
lcdf <- lcdf %>% select(-nm)
colMeans(is.na(lcdf))[colMeans(is.na(lcdf))>0]
nm<- names(lcdf)[colSums(is.na(lcdf))>0]
summary(lcdf[, nm])
lcx<-lcdf[, c(nm)]
colMeans(is.na(lcx))[colMeans(is.na(lcx))>0]
lcx<- lcx %>% replace_na(list(mths_since_last_delinq = 500))
#For revol_util, suppose we want to replace the misisng values by the median
lcx<- lcx %>% replace_na(list(revol_util=median(lcx$revol_util, na.rm=TRUE)))
lcx$revol_util
summary(lcx[, nm])
lcdf<- lcdf %>% replace_na(list(mths_since_last_delinq=500, revol_util=median(lcdf$revol_util, na.rm=TRUE), bc_open_to_buy=median(lcdf$bc_open_to_buy, na.rm=TRUE), mo_sin_old_il_acct=1000, mths_since_recent_bc=1000, mths_since_recent_inq=50, num_tl_120dpd_2m = median(lcdf$num_tl_120dpd_2m, na.rm=TRUE),percent_bc_gt_75 = median(lcdf$percent_bc_gt_75, na.rm=TRUE), bc_util=median(lcdf$bc_util, na.rm=TRUE) ))

##Question 3 - Removing Leakage Variables
lcdf2 <- lcdf %>% select(-c(debt_settlement_flag,issue_d,initial_list_status,chargeoff_within_12_mths,num_tl_30dpd,collections_12_mths_ex_med,application_type,tot_cur_bal,bc_util,dti,earliest_cr_line,addr_state,total_pymnt_inv,total_pymnt,loan_amnt,emp_title, actualReturn, actualTerm, recoveries, collection_recovery_fee,last_credit_pull_d,total_rec_prncp, actualTerm, title, zip_code,funded_amnt, funded_amnt_inv, verification_status))
varsToRemove <- c("last_pymnt_d","last_pymnt_amnt","annRet")
lcdf2 <- lcdf2 %>% select(-varsToRemove)
View(lcdf2)

glimpse(lcdf2)
lcdf3 <- lcdf2 %>% select(-c(funded_amnt, funded_amnt_inv, verification_status, mort_acc, title))
##Question 4 - univariate analysis
library(pROC)
auc(response=lcdf2$loan_status, lcdf2$loan_amnt)
auc(response=lcdf2$loan_status, as.numeric(lcdf2$emp_length))
aucsNum<-sapply(lcdf2 %>% select_if(is.numeric), auc, response=lcdf2$loan_status)
auc(response=lcdf2$loan_status, as.numeric(lcdf2$emp_length))
aucAll<- sapply(lcdf2 %>% mutate_if(is.factor, as.numeric) %>% select_if(is.numeric), auc, response=lcdf2$loan_status)
library(broom)

tidy(aucAll[aucAll > 0.54]) %>% View() #TO determine which variables have auc > 0.54
tidy(aucAll[aucAll >=0.55 & aucAll < 0.59]) %>% View() #TO determine which variables have auc between 0.54 and 0.59

view(lcdf)
lcdf3$loan_status <- factor(lcdf3$loan_status, levels=c("Fully Paid", "Charged Off"))
lcdf2$loan_status <- factor(lcdf$loan_status, levels=c("Fully Paid", "Charged Off"))
TRNPROP = 0.7
nr<-nrow(lcdf2)
trnIndex<- sample(1:nr, size = round(TRNPROP*nr), replace=FALSE)
lcdfTrn <- lcdf2[trnIndex, ]
lcdfTst <- lcdf2[-trnIndex, ]
library(rpart)
#Decision tree using professor's code
rpDT22 <- rpart(loan_status ~ ., data= lcdfTrn, method = "class")
printcp(rpDT22)
rpDT22$variable.importance
print(rpDT22)
library(rpart.plot)
rpart.plot::prp(rpDT22, type=2, extra=1) 
summary(rpDT22)
printcp(rpDT22)
rpDT22$variable.importance
###Decision tree 1
lcDT1 <- rpart(loan_status ~., data=lcdfTrn, method="class", parms = list(split = "information"), control = rpart.control(minsplit = 30, cp = 0.0001))
#rpart.plot::prp(lcDT1, type=2, extra=1)
printcp(lcDT1)
lcDT1$variable.importance
###
summary(lcDT1)
printcp(lcDT1)
lcDT1$variable.importance
#decision tree 2
lcDT2 = rpart(loan_status ~ ., data=lcdfTrn, method="class",parms = list(split = "gini"), control = 
                 rpart.control(cp=0.0001,maxdepth=6))
library(rpart.plot)
rpart.plot::prp(lcDT2, type=2, extra=1) 
printcp(lcDT2)
lcDT2$variable.importance
#prediction
predTrn2=predict(lcDT2, lcdfTrn, type = 'class')
head(predTrn2)
table(pred = predTrn2, true=lcdfTrn$loan_status)
mean(predTrn2 == lcdfTrn$loan_status)

predTst=predict(lcDT2, lcdfTst, type = 'class')
mean(predTst == lcdfTst$loan_status)
table(pred = predict(lcDT2, lcdfTst, type = 'class'), true=lcdfTst$loan_status)
####rpDt4
rpDT4 <- rpart(loan_status ~ ., data=lcdfTrn, method="class",
               parms = list(split = "information"),
               control = rpart.control(minsplit = 20, minbucket = 10, cp=0)) 
table(pred=predict(rpDT4,lcdfTrn, type="class"), true=lcdfTrn$loan_status)
predTrn4=predict(rpDT4, lcdfTrn, type = 'class')
head(predTrn4)
table(pred = predTrn4, true=lcdfTrn$loan_status)
mean(predTrn4 == lcdfTrn$loan_status)

predTst4=predict(rpDT4, lcdfTst, type = 'class')
mean(predTst4 == lcdfTst$loan_status)
#scores
predTrnProb=predict(rpDT4, lcdfTrn, type='prob')
head(predTrnProb)

#pruning
printcp(lcDT2)
printcp(rpDT4)
summary(lcDT2)
lcDT2$variable.importance




####c5.0
library(C50)
lcdf2$loan_status <- factor(lcdf2$loan_status, levels=c("Fully Paid", "Charged Off"))
TRNPROP = 0.7
nr<-nrow(lcdf2)
trnIndex<- sample(1:nr, size = round(TRNPROP*nr), replace=FALSE)
lcdfTrn <- lcdf2[trnIndex, ]
lcdfTst <- lcdf2[-trnIndex, ]
dim(lcdfTrn)
dim(lcdfTst)
lcdf4 <- lcdf2
lcdf4$loan_status <- as.factor(lcdf4$loan_status)
lcdfTrn$loan_status <- as.factor(lcdfTrn$loan_status)
lcdfTst$loan_status <- as.factor(lcdfTst$loan_status)

c5_DT1 <- C5.0(loan_status ~ ., data=lcdfTrn, control=C5.0Control(minCases=10))
summary(c5_DT1)
cModel3 <- C5.0(loan_status~., data=lcdf2, sample=.5, winnow=F, earlyStopping=F, noGlobalPruning=T, rules=F)
summary(cModel3)
cModel31 <- C5.0(loan_status~., data=lcdf2, sample=.5, winnow=T, earlyStopping=F, noGlobalPruning=T, rules=F)
summary(cModel31)
c5_rules1 <- C5.0(loan_status ~ ., data=lcdfTrn, control=C5.0Control(minCases=20), rules=TRUE)
summary(c5_rules1)

#Do we want to prune the tree -- check for performance with different cp levels
printcp(lcDT1)
lcDT1p<- prune.rpart(lcDT1, cp=0.001)

### rpDT2
rpDT2 <- rpart(loan_status ~., data=lcdfTrn, method="class", parms = list(split = "information"), control = rpart.control(minsplit = 30, cp = 0.001))
rpart.plot::prp(rpDT2, type=2, extra=1)
table(pred=predict(rpDT2,lcdfTrn, type="class"), true=lcdfTrn$loan_status)
table(pred=predict(rpDT2,lcdfTst, type="class"), true=lcdfTst$loan_status)








printcp(lcDT1p)
summary(lcDT1)

library(rattle)
library(rpart.plot)
library(RColorBrewer)

