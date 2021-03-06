/***************************************** Import data sets *****************************************/

/* Import Project 2 Kobe Bryant Shot Selection Dataset */
Proc Import Out = KobeShotData
			Datafile = "/home/dandreev0/MSDS 6372/Unit 13 - Project 2/KobeDataProj2.csv" 
			Dbms = csv Replace; 
			Getnames = YES; 
			Datarow = 2; 
Run;

/* Create Train and Test datasets by subsetting original KobeShotData using conditional if statement */
Data Train;
 Set KobeShotData;
 if shot_made_flag = 'NA' then delete;
Run;

Data Test;
 Set KobeShotData;
 if shot_made_flag = 'NA' then output;
Run;

/* Clean test dataset - remove NA values from shot_made_flag variable and replace with blank */
Data TestClean;
 set Test;
 if shot_made_flag = "NA" then shot_made_flag = "";
Run;

/* Train dataset summary statistics */
Proc Means Data = Train;
Run;

/* Test dataset summary statistics */
Proc Means Data = TestClean;
Run;


/********************************* Look into NA missing values *********************************/

/* Run proc format, freq, and iml procedures to count missing values in train data set */
Proc Iml;
 Use Train;
 Read All Var _NUM_ into x[colname=nNames]; 
 n = countn(x,"col");
 nmiss = countmiss(x,"col");
 
Read All Var _CHAR_ into x[colname=cNames]; 
 Close Train;
 c = countn(x,"col");
 cmiss = countmiss(x,"col");
 
 Names = cNames || nNames;/* combine results for num and char into a single table */
 rNames = {"    Missing", "Not Missing"};
 cnt = (cmiss // c) || (nmiss // n);
Print cnt[r=rNames c=Names label=""];

/* Run proc format, freq, and iml procedures to count missing values in test data set */
Proc Iml;
 Use Test;
 Read All Var _NUM_ into x[colname=nNames]; 
 n = countn(x,"col");
 nmiss = countmiss(x,"col");
 
Read All Var _CHAR_ into x[colname=cNames]; 
 Close Test;
 c = countn(x,"col");
 cmiss = countmiss(x,"col");
 
 Names = cNames || nNames;/* combine results for num and char into a single table */
 rNames = {"    Missing", "Not Missing"};
 cnt = (cmiss // c) || (nmiss // n);
Print cnt[r=rNames c=Names label=""];


/******************************** Interpretation Models / Questions ******************************/

/* Question 1 - odds of Kobe making a shot decrease with respect to the distance he is from the hoop */
Proc Sort Data = Train;
 by shot_distance;
Run;

Proc SGPlot Data = Train;
 Scatter y = shot_made_flag x = shot_distance;
Run;

Proc Logistic Data = Train plots(only) = (fitplot(extend = 0));
 Class shot_made_flag (ref = "0") / param = ref;
 model shot_made_flag = shot_distance / ctable clparm = Wald lackfit;
Run;

/* Lack of fit model has pvalue < 0.0001 suggesting that logit(shot_made_flag) is not lineargly related
with shot_distance. Need to investigate how to handle the non-linaerity. Looking at the probability
versus distance graph shows us that the relationship is linear between 0ft - 40ft and begins to curve
exponentially 40ft - 80ft  */
   
/* Run proc freq to see cumulative percentage of shots made with distance */  
Proc Freq Data = Train;
 Tables shot_distance / out = t;
Run;

/* We can see that at 30ft is 99.36 percentage of shots made so we can try to rerun logistic regression 
against distance but limit to within 30 ft */  

Proc Logistic Data = Train plots(only) = (fitplot(extend = 0));
 Class shot_made_flag (ref = "0") / param = ref;
 where shot_distance <= 30;
 model shot_made_flag = shot_distance / ctable clparm = Wald lackfit;
Run;

/* Lack of fit model still has pvalue < 0.0001 suggesting that logit(shot_made_flag) is not lineargly related
with shot_distance but graphically the model looks linear */


/* Question 2 - probability of Kobe making a shot decreases linearly with respect to the distance he is from the hoop */