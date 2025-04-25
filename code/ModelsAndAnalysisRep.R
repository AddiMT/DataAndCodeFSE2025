## -------------------------------------------------------------------------------------------------------------------------------------------------------

if (!requireNamespace("survminer", quietly = TRUE)) install.packages("survminer")



## -------------------------------------------------------------------------------------------------------------------------------------------------------


if (!requireNamespace("gtools", quietly = TRUE)) install.packages("gtools")




## -------------------------------------------------------------------------------------------------------------------------------------------------------

if (!requireNamespace("survival", quietly = TRUE)) install.packages("survival")




## -------------------------------------------------------------------------------------------------------------------------------------------------------

if (!requireNamespace("xtable", quietly = TRUE)) install.packages("xtable")



## -------------------------------------------------------------------------------------------------------------------------------------------------------
a4=read.table("../aP4-t.csv",sep=";",header=T,quote="",comment.char="")
colnames(a4)



## -------------------------------------------------------------------------------------------------------------------------------------------------------
bad4=a4$LatestCommitDate/3600/24/365.25+1970>2023.8
x14=a4[!bad4,]

for (i in c("c.mlcddP","c.mlcduP","d.mlcddP","d.mlcduP")){
   z4 = x14[,i];
   z4[z4=="null"] = "NA";
   z4=as.integer(z4)
   x14[,i]=z4
}
pnames4=c()
for (i in c("NumCore", "CommunitySize", "NumForks", "NumCommits", "NumFiles",
            "NumBlobs", "NumStars", "d.nuP", "d.ndP", "d.nPkg", "d.nDef", "NumAuthors")){
 f4 = paste("l",i,sep="")
 pnames4=c(pnames4,f4)
 x14[, f4 ]=log(as.integer(x14[,i])+1);
 x14[is.na(x14[, f4 ]), f4 ]=0;
 print(sum(is.na(x14[,f4])))
}


## -------------------------------------------------------------------------------------------------------------------------------------------------------
nrow(x14)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
hiCor4 <- function(x, level){
  res4 <- cor(x,method="spearman");
  res14 <- res4;
  res14[res4<0] <- -res4[res4 < 0];
  for (i in 1:dim(x)[2]){
    res14[i,i] <- 0;
  }
  sel4 <- apply(res14,1,max) > level;
  res4[sel4,sel4];
}
hiCor4(x14[,c("EarliestCommitDate","LatestCommitDate",pnames4)],.9)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
hiCor4(x14[,c("EarliestCommitDate","LatestCommitDate","lNumCore", "lCommunitySize", "lNumCommits", "lNumFiles","lNumStars", "ld.nuP", "ld.ndP", "ld.nPkg", "ld.nDef","lNumAuthors")],.6)



## -------------------------------------------------------------------------------------------------------------------------------------------------------
hiCor4(x14[,c("EarliestCommitDate","LatestCommitDate","lNumCore", "lCommunitySize", "lNumCommits", "ld.nuP", "ld.ndP", "ld.nPkg", "ld.nDef")],.6)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
hiCor4(x14[,c("EarliestCommitDate","LatestCommitDate","lNumCore", "lCommunitySize", "lNumCommits", "ld.nuP", "ld.ndP", "ld.nPkg")],.6)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
table(x14$d.mlcduP<=x14$EarliestCommitDate,x14$d.mlcddP>=x14$LatestCommitDate)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
table(x14$d.mlcduP<=x14$EarliestCommitDate,x14$d.mlcddP>=x14$LatestCommitDate)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
table(x14$c.mlcduP<=x14$EarliestCommitDate,x14$c.mlcddP>=x14$LatestCommitDate)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
x14$noUp = is.na(x14$d.mlcduP)
x14$noDwn = is.na(x14$d.mlcddP)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
library(survival)


## -------------------------------------------------------------------------------------------------------------------------------------------------------

y4=Surv(-((x14$EarliestCommitDate-x14$LatestCommitDate)/3600/365.25/24),event=x14$LatestCommitDate/3600/365.25/24+1970 <= 2023)



## -------------------------------------------------------------------------------------------------------------------------------------------------------
mod041 = coxph(y4~lNumCore+lCommunitySize+lNumCommits+I(EarliestCommitDate/3600/24/365.25+1970)+I((log(exp(ld.nuP)/exp(ld.nPkg))*.1))+I(ld.ndP*.1)+I(ld.nDef*.1)+gov2+edu2+LayerName+Field+I(language=="C/C++")+I(language=="R")+I(language=="Python")+I(language=="Java")+I(language=="Fortran")+I(mentionsPaperOrFunding=="Yes"),data=x14,subs=x14$isSci==1)
cf041=summary(mod041)$coefficients[,c(1,5)]
print(cf041)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf041[cf041[,2]<.01,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf041[cf041[,2]<.02,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
zfit <- cox.zph(mod041)
par(mfrow=c(3,3));
plot(zfit,pch=".");


## -------------------------------------------------------------------------------------------------------------------------------------------------------
y4.18=Surv(-((x14$EarliestCommitDate-x14$LatestCommitDate)/3600/365.25/24),event=x14$LatestCommitDate/3600/365.25/24+1970
<= 2022)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
mod041.18 = coxph(y4.18~lNumCore+lCommunitySize+lNumCommits+I(EarliestCommitDate/3600/24/365.25+1970)+I((log(exp(ld.nuP)/exp(ld.nPkg))*.1))+I(ld.ndP*.1)+I(ld.nDef*.1)+gov2+edu2+LayerName+Field+I(language=="C/C++")+I(language=="R")+I(language=="Python")+I(language=="Java")+I(language=="Fortran")+I(mentionsPaperOrFunding=="Yes"),data=x14,subs=x14$isSci==1)
cf041.18=summary(mod041.18)$coefficients[,c(1,5)]
print(cf041.18)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf041.18[cf041.18[,2]<.01,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf041.18[cf041.18[,2]<.02,]

## -------------------------------------------------------------------------------------------------------------------------------------------------------
zfit.18 <- cox.zph(mod041.18)
plot(zfit.18,pch=".")


## -------------------------------------------------------------------------------------------------------------------------------------------------------
y4.24=Surv(-((x14$EarliestCommitDate-x14$LatestCommitDate)/3600/365.25/24),event=x14$LatestCommitDate/3600/365.25/24+1970
<= 2021.5)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
mod041.24 = coxph(y4.24~lNumCore+lCommunitySize+lNumCommits+I(EarliestCommitDate/3600/24/365.25+1970)+I((log(exp(ld.nuP)/exp(ld.nPkg))*.1))+I(ld.ndP*.1)+I(ld.nDef*.1)+gov2+edu2+LayerName+Field+I(language=="C/C++")+I(language=="R")+I(language=="Python")+I(language=="Java")+I(language=="Fortran")+I(mentionsPaperOrFunding=="Yes"),data=x14,subs=x14$isSci==1)
cf041.24=summary(mod041.24)$coefficients[,c(1,5)]
print(cf041.24)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf041.24[cf041.24[,2]<.01,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf041.24[cf041.24[,2]<.02,]

## -------------------------------------------------------------------------------------------------------------------------------------------------------
zfit.24 <- cox.zph(mod041.24)
plot(zfit.24,pch=".")

## Any change in coefficient direction compare 24 m and 6m
sum(cf041.24[cf041[,1]<0,1]>0)
sum(cf041.24[cf041[,1]>0,1]<0)

## Any change in coefficient direction compare 18 m and 6m
sum(cf041.18[cf041[,1]<0,1]>0)
sum(cf041.18[cf041[,1]>0,1]<0)
#C++ flips, but p-value is 0.9

## -------------------------------------------------------------------------------------------------------------------------------------------------------

library(survival)
y4=Surv(-((x14$EarliestCommitDate-x14$LatestCommitDate)/3600/365.25/24),event=x14$LatestCommitDate/3600/365.25/24+1970 <= 2023)




## -------------------------------------------------------------------------------------------------------------------------------------------------------
mod243 = coxph(y4~isSci+I((log(exp(ld.nuP)/exp(ld.nPkg))*.1))+
I(ld.ndP * 0.1)+I(EarliestCommitDate / 3600 / 24 / 365.25 + 1970)+I(ld.nDef * 0.1) +lNumCore+lCommunitySize+lNumCommits+gov2+edu2+I(language=="C/C++")+I(language=="R")+I(language=="Python")+I(language=="Java"),data=x14)
cf243=summary(mod243)$coefficients[,c(1,5)]
print(cf243)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf243[cf243[,2]<.01,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf243[cf243[,2]<.02,]

## -------------------------------------------------------------------------------------------------------------------------------------------------------
scinosszfit <- cox.zph(mod243)
plot(scinosszfit, pch=".")


## -------------------------------------------------------------------------------------------------------------------------------------------------------
y4.18=Surv(-((x14$EarliestCommitDate-x14$LatestCommitDate)/3600/365.25/24),event=x14$LatestCommitDate/3600/365.25/24+1970
<= 2022)




## -------------------------------------------------------------------------------------------------------------------------------------------------------
mod243.18 = coxph(y4.18~isSci+I((log(exp(ld.nuP)/exp(ld.nPkg))*.1))+
I(ld.ndP * 0.1)+I(EarliestCommitDate / 3600 / 24 / 365.25 + 1970)+I(ld.nDef * 0.1) +lNumCore+lCommunitySize+lNumCommits+gov2+edu2+I(language=="C/C++")+I(language=="R")+I(language=="Python")+I(language=="Java"),data=x14)
cf243.18=summary(mod243.18)$coefficients[,c(1,5)]
print(cf243.18, pch=".")


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf243.18[cf243.18[,2]<.01,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf243.18[cf243.18[,2]<.02,]

## -------------------------------------------------------------------------------------------------------------------------------------------------------
scinosszfit.18 <- cox.zph(mod243.18)
plot(scinosszfit.18, pch=".")


## -------------------------------------------------------------------------------------------------------------------------------------------------------
y4.24=Surv(-((x14$EarliestCommitDate-x14$LatestCommitDate)/3600/365.25/24),event=x14$LatestCommitDate/3600/365.25/24+1970
<= 2021.5)



## -------------------------------------------------------------------------------------------------------------------------------------------------------
mod243.24 = coxph(y4.24~isSci+I((log(exp(ld.nuP)/exp(ld.nPkg))*.1))+
I(ld.ndP * 0.1)+I(EarliestCommitDate / 3600 / 24 / 365.25 + 1970)+I(ld.nDef * 0.1) +lNumCore+lCommunitySize+lNumCommits+gov2+edu2+I(language=="C/C++")+I(language=="R")+I(language=="Python")+I(language=="Java"),data=x14)
cf243.24=summary(mod243.24)$coefficients[,c(1,5)]
print(cf243.24)


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf243.24[cf243.24[,2]<.01,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
cf243.24[cf243.24[,2]<.02,]


## -------------------------------------------------------------------------------------------------------------------------------------------------------
scinosszfit.24 <- cox.zph(mod243.24)
plot(scinosszfit.24, pch=".")

## Any change in coefficient direction compare 24 m and 6m
sum(cf243.24[cf243[,1]<0,1]>0)
sum(cf243.24[cf243[,1]>0,1]<0)
# ld.nDef flips, but was not significant in the original

## Any change in coefficient direction compare 18 m and 6m
sum(cf243.18[cf243[,1]<0,1]>0)
sum(cf243.18[cf243[,1]>0,1]<0)
#ld.nDef and C++ flips, but p-value is 0.9 and 0.7 in the original model



## -------------------------------------------------------------------------------------------------------------------------------------------------------

## Load necessary libraries
library(tidyverse)
library(broom)
library(gtools)
library(survival)
library(survminer)

# Convert necessary columns to numeric after checking their types
x14fg1 <- x14 %>%
  mutate(
    Language_C_Cpp = as.numeric(language == "C/C++"),
    Language_R = as.numeric(language == "R"),
    Language_Python = as.numeric(language == "Python"),
    Language_Java = as.numeric(language == "Java"),
    Language_Fortran = as.numeric(language == "Fortran"),
    Mentions_Paper_or_Funding = as.numeric(mentionsPaperOrFunding == "Yes"),  # Correctly renamed variable
    noUp = as.numeric(noUp),  # Convert logical to numeric for upstream projects
    noDwn = as.numeric(noDwn), # Convert logical to numeric for downstream projects
    ldnuP_ldnPkg_ratio = (log(exp(ld.nuP)/exp(ld.nPkg))*.1),
    unitchange_ld_ndP = ld.ndP * 0.1,
    unitchange_EarliestCommitDate = EarliestCommitDate / 3600 / 24 / 365.25 + 1970,
    unitchange_ld_nDef = ld.nDef * 0.1
  )



 # Fit Cox proportional hazards model
 mod041fg <- coxph(y4 ~ unitchange_EarliestCommitDate+lNumCore +lCommunitySize+ lNumCommits
                   + unitchange_ld_nDef + ldnuP_ldnPkg_ratio + unitchange_ld_ndP + Language_C_Cpp +
                   Language_R + Language_Python + Language_Java + Language_Fortran +
                   edu2 + gov2  + LayerName + Field + Mentions_Paper_or_Funding,
                 data = x14fg1, subset = (x14fg1$isSci == 1))


# Extract the summary and tidy the coefficients
coeffsfg1 <- as.data.frame(summary(mod041fg)$coefficients) %>%
  rownames_to_column(var = "term")

# Calculate hazard ratios, confidence intervals, and p-values
hr_labsfg1 <- coeffsfg1 %>%
  mutate(
    OR = exp(coef),  # Use the correct column for the coefficient estimate
    lower = exp(coef - 1.96 * `se(coef)`),  # Standard error column is `se(coef)`
    upper = exp(coef + 1.96 * `se(coef)`),
    p.val = `Pr(>|z|)`,  # Column for p-values
    p.val.adjusted = p.adjust(p.val, method = "bonferroni"),  # Apply Bonferroni correction
    sig = case_when(
      p.val.adjusted < 0.001 ~ "***",
      p.val.adjusted < 0.01 ~ "**",
      p.val.adjusted < 0.05 ~ "*",
      #TRUE ~ "p >= 0.05"
      TRUE ~ ""
    )
  )

  # Create shape categories based on hazard ratios
hr_labsfg1 <- hr_labsfg1 %>%
  mutate(shape_category = case_when(
    OR <= 0.99 ~ "HR <= 0.99",   # Hazard Ratio less than or equal to 0.99
    OR >= 1.01 ~ "HR >= 1.01",   # Hazard Ratio greater than or equal to 1.01
    TRUE ~ "HR = 1"              # Hazard Ratio close to 1
  ))


hr_labsfg1 <- hr_labsfg1 %>%
  mutate(
    term = str_replace(term, "unitchange_EarliestCommitDate", "Earliest Commit Year"),
    term = str_replace(term, "lNumCore", "Num. Core Authors (log)"),
    term = str_replace(term, "lCommunitySize", "Community Size (log)"),
    term = str_replace(term, "lNumCommits", "Num. Commits (log)"),
    term = str_replace(term, "Brst", "Burstiness"),
    term = str_replace(term, "unitchange_ld_nDef", "Num. Defined Packages (log)"),
    term = str_replace(term, "ldnuP_ldnPkg_ratio", "Upstream Package Ratio"),
    term = str_replace(term, "unitchange_ld_ndP", "Num. Downstream Projects (log)"),
    term = str_replace(term, "Language_C_Cpp", "Language: C/C++"),
    term = str_replace(term, "Language_R", "Language: R"),
    term = str_replace(term, "Language_Python", "Language: Python"),
    term = str_replace(term, "Language_Java", "Language: Java"),
    term = str_replace(term, "Language_Fortran", "Language: Fortran"),
    term = str_replace(term, "edu2", "Has Academic Participants"),
    term = str_replace(term, "gov2", "Has Government Participants"),
    term = str_replace(term, "LayerNamePublication-Specific code", "Layer: Publication-specific code"),
    term = str_replace(term,"LayerNameScientific Domain-specific code","Layer: Scientific domain-specific code"),
    term = str_replace(term,"LayerNameScientific infrastructure","Layer: Scientific infrastructure"),
    #term = str_replace(term, "LayerName", "Layer: "),
    term = str_replace(term, "Field", "Field: "),
    term = str_replace(term, "Mentions_Paper_or_Funding", "Mentions Paper or Funding")
  )


  desired_order <- c(
  "Num. Core Authors (log)",
  "Num. Commits (log)",
  "Community Size (log)",
  "Earliest Commit Year",
  "Num. Defined Packages (log)",
  "Upstream Package Ratio",
  "Num. Downstream Projects (log)",
  "Language: C/C++",
  "Language: Fortran",
  "Language: Java",
  "Language: Python",
  "Language: R",
  "Layer: Publication-specific code",
  "Layer: Scientific domain-specific code",
  "Layer: Scientific infrastructure",
  "Field: Biology",
  "Field: Chemistry",
  "Field: Computer Science",
  "Field: Data Science",
  "Field: Earth Science",
  "Field: Engineering",
  "Field: Mathematics",
  "Field: Medicine",
  "Field: Neuroscience",
  "Field: Physics",
  "Field: Quantum Computing",
  "Field: Statistics",
  "Mentions Paper or Funding",
  "Has Government Participants",
  "Has Academic Participants"

)

# Convert term into a factor with the specified order
hr_labsfg1 <- hr_labsfg1 %>%
  mutate(term = factor(term, levels = rev(desired_order)))  # Reverse to match ggplot default order



# Modify the geom_text call to map p-values to the significance legend
forest_plot4b2fg1 <- ggplot(hr_labsfg1, aes(OR, term, color = OR > 1, shape = shape_category)) +
  geom_vline(xintercept = 1, color = "gray70", size = 1) + # Bolder vertical line
  geom_linerange(aes(xmin = lower, xmax = upper), size = 2, alpha = 0.6) + # Bolder and more opaque lines
  geom_point(size = 5) +  # Increase point size for better visibility
  theme_minimal() +
  scale_shape_manual(values = c("HR <= 0.99" = 16, "HR = 1" = 15, "HR >= 1.01" = 17)) +  # Define custom shapes
  # scale_color_manual(values = c("#FF0000", "#00A08A"), guide = "none") +
    scale_color_manual(values = c("#00A08A","#FF0000"), guide = "none") +
  xlim(c(0.5, 2.3)) +  # Zoom in on the x-axis
  labs(
    #title = "",
    x = "               Hazard Ratio Estimate (Bonferroni adjusted ***p < 0.001, **p < 0.01, *p < 0.05)",
    y = NULL
  ) +
  theme(
    axis.text.x = element_text(size = 14, color = "black"),
    axis.text.y = element_text(hjust = 0, size = 16, color = "black"),  # Larger y-axis text
    axis.title.x = element_text(hjust = 0, size = 14, color = "black", margin = margin(t = 15)), # Larger x-axis title
    plot.title = element_text(size = 20, face = "bold"),  # Larger and bold plot title
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_line(size = 0.5),  # Clearer grid lines
    legend.position = "none" , # Do not display the legend, but shapes remain
    plot.margin = margin(20, 10, 40, 10)  # Add margin to the top
  ) +
  geom_text(
    aes(label = paste0("HR = ", round(OR, 2),
                       ifelse(p.val.adjusted < 0.001, "***",
                       ifelse(p.val.adjusted < 0.01, "**",
                       ifelse(p.val.adjusted   < 0.05, "*", " "))))),# p >= 0.05"))))), p >= 0.05"))))),
    nudge_x = 0.4, nudge_y = 0.3, check_overlap = TRUE, color = "black", size = 5  # Larger text for HR and p-values
  )

# Save the plot to a file with wider dimensions
ggsave("forest_plot_sci_022425_latestversion_corrected_v24.pdf", width = 14, height = 9)  # Increased width
ggsave("forest_plot_sci_022425_latestversion_corrected_v24.png", plot = forest_plot4b2fg1, width = 10, height = 6, dpi = 300)

# Display the plot
print(forest_plot4b2fg1)



## -------------------------------------------------------------------------------------------------------------------------------------------------------

# Load necessary libraries
library(tidyverse)
library(broom)
library(gtools)
library(survival)
library(survminer)

# Check the structure of the dataset to identify non-numeric variables
str(x14)

# Convert necessary columns to numeric after checking their types
x14f1 <- x14 %>%
  mutate(
    language_C_Cpp = as.numeric(language == "C/C++"),
    language_R = as.numeric(language == "R"),
    language_Python = as.numeric(language == "Python"),
    language_Java = as.numeric(language == "Java"),
    PaperOrFunding_Yes = as.numeric(mentionsPaperOrFunding == "Yes"),
    noUp = as.numeric(noUp),  # Convert logical to numeric
    noDwn = as.numeric(noDwn), # Convert logical to numeric
    ldnuP_ldnPkg_ratio = (log(exp(ld.nuP)/exp(ld.nPkg))*.1),
    unitchange_ld_ndP = ld.ndP * 0.1,
    unitchange_EarliestCommitDate = EarliestCommitDate / 3600 / 24 / 365.25 + 1970,
    unitchange_ld_nDef = ld.nDef * 0.1
  )

# Check for any NA values or problematic types after mutation
summary(x14f1)
str(x14f1)


mod243 = coxph(y4~isSci+ ldnuP_ldnPkg_ratio+
               unitchange_ld_ndP + unitchange_EarliestCommitDate + lNumCore+lCommunitySize+lNumCommits
               + unitchange_ld_nDef + gov2 + edu2 +
              language_C_Cpp + language_R + language_Python +
              language_Java, data = x14f1)


# Extract the summary and tidy the coefficients
coeffs1 <- as.data.frame(summary(mod243)$coefficients) %>%
  rownames_to_column(var = "term")


# Calculate hazard ratios, confidence intervals, and p-values
hr_labs1 <- coeffs1 %>%
  mutate(
    OR = exp(coef),  # Use the correct column for the coefficient estimate
    lower = exp(coef - 1.96 * `se(coef)`),  # Standard error column is `se(coef)`
    upper = exp(coef + 1.96 * `se(coef)`),
    p.val = `Pr(>|z|)`,  # Column for p-values
    # p.val.formatted = format.pval(p.val, digits = 2, eps = 0.001),
    # sig = stars.pval(p.val)  # Significance stars
     p.val.adjusted = p.adjust(p.val, method = "bonferroni"),  # Apply Bonferroni correction
    sig = case_when(
      p.val.adjusted < 0.001 ~ "***",
      p.val.adjusted < 0.01 ~ "**",
      p.val.adjusted < 0.05 ~ "*",
      #TRUE ~ "p >= 0.05"
      TRUE ~ ""
    )
  )


  # Create shape categories based on hazard ratios
hr_labs1 <- hr_labs1 %>%
  mutate(shape_category = case_when(
    OR <= 0.99 ~ "HR <= 0.99",   # Hazard Ratio less than or equal to 0.99
    OR >= 1.01 ~ "HR >= 1.01",   # Hazard Ratio greater than or equal to 1.01
    TRUE ~ "HR = 1"              # Hazard Ratio close to 1
  ))


hr_labs1 <- hr_labs1 %>%
  mutate(
    term = str_replace(term, "unitchange_EarliestCommitDate", "Earliest Commit Year"),
    term = str_replace(term, "lNumCore", "Num. Core Authors (log)"),
    term = str_replace(term, "lCommunitySize", "Community Size (log)"),
    term = str_replace(term, "lNumCommits", "Num. Commits (log)"),
    term = str_replace(term, "Brst", "Burstiness"),
    term = str_replace(term, "unitchange_ld_nDef", "Num. Defined Packages (log)"),
    term = str_replace(term, "ldnuP_ldnPkg_ratio", "Upstream Package Ratio"),
    term = str_replace(term, "unitchange_ld_ndP", "Num. Downstream Projects (log)"), # or "Num. Downstream Dependents (log)"

    term = str_replace(term, "language_C_Cpp", "Language: C/C++"),
    term = str_replace(term, "language_R", "Language: R"),
    term = str_replace(term, "language_Python", "Language: Python"),
    term = str_replace(term, "language_Java", "Language: Java"),
    term = str_replace(term, "language_Fortran", "Language: Fortran"),
    term = str_replace(term, "edu2", "Has Academic Participants"),
    term = str_replace(term, "gov2", "Has Government Participants"),
    term = str_replace(term, "LayerName", "Layer: "),
    term = str_replace(term, "Field", "Field: "),
    term = str_replace(term, "isSci", "Is Scientific Software"),
    term = str_replace(term, "Mentions_Paper_or_Funding", "Mentions Paper or Funding")

  )

  desired_order <- c(
  "Num. Core Authors (log)",
  "Num. Commits (log)",
  "Community Size (log)",
  "Earliest Commit Year",
  "Num. Defined Packages (log)",
  "Upstream Package Ratio",
  "Num. Downstream Projects (log)",
  "Language: C/C++",
  "Language: Fortran",
  "Language: Java",
  "Language: Python",
  "Language: R",
  "Layer: Publication-Specific code",
  "Layer: Scientific Domain-specific code",
  "Layer: Scientific infrastructure",
  "Field: Biology",
  "Field: Chemistry",
  "Field: Computer Science",
  "Field: Data Science",
  "Field: Earth Science",
  "Field: Engineering",
  "Field: Mathematics",
  "Field: Medicine",
  "Field: Neuroscience",
  "Field: Physics",
  "Field: Quantum Computing",
  "Field: Statistics",
  "Mentions Paper or Funding",
  "Has Government Participants",
  "Has Academic Participants",
  "Is Scientific Software"

)

# Convert term into a factor with the specified order
hr_labs1 <- hr_labs1 %>%
  mutate(term = factor(term, levels = rev(desired_order)))  # Reverse to match ggplot default order


# Create the forest plot using ggplot with adjustments for size and layout
forest_plot4b21 <- ggplot(hr_labs1, aes(OR, term, color = OR > 1, shape = shape_category)) +
  geom_vline(xintercept = 1, color = "gray70", size = 1) + # Bolder vertical line
  geom_linerange(aes(xmin = lower, xmax = upper), size = 2, alpha = 0.6) + # Bolder and more opaque lines
  geom_point(size = 5) +  # Increase point size for better visibility
  theme_minimal() +
  scale_shape_manual(values = c("HR <= 0.99" = 16, "HR = 1" = 15, "HR >= 1.01" = 17)) +  # Define custom shapes
  # scale_color_manual(values = c("#FF0000", "#00A08A"), guide = "none") +
  scale_color_manual(values = c("#00A08A", "#FF0000"), guide = "none") +
  xlim(c(0.5, 2.3)) +  # Zoom in on the x-axis
  labs(
    #title = "",
    x = "               Hazard Ratio Estimate (Bonferroni adjusted ***p < 0.001, **p < 0.01, *p < 0.05)",
    y = NULL
  ) +
  theme(
    axis.text.x = element_text(size = 14, color = "black"),
    axis.text.y = element_text(hjust = 0, size = 16, color = "black"),  # Larger y-axis text
    axis.title.x = element_text(hjust = 0, size = 14, color = "black", margin = margin(t = 15)), # Larger x-axis title
    plot.title = element_text(size = 20, face = "bold"),  # Larger and bold plot title
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_line(size = 0.5),  # Clearer grid lines
    legend.position = "none" , # Do not display the legend, but shapes remain
    plot.margin = margin(20, 10, 40, 10)  # Add margin to the top
  ) +
  geom_text(
    aes(label = paste0("HR = ", round(OR, 2),
                       ifelse(p.val.adjusted < 0.001, "***",
                       ifelse(p.val.adjusted < 0.01, "**",
                       ifelse(p.val.adjusted < 0.05, "*", " "))))),# p >= 0.05"))))),
    nudge_x = 0.4, nudge_y = 0.3, check_overlap = TRUE, color = "black", size = 5  # Larger text for HR and p-values
  )

# Save the plot to a file with optimized dimensions
ggsave("forest_plot_sci_plus_matched_022425_latestversion_v10.pdf", width = 14, height = 6)
ggsave("forest_plot_sci_plus_matched_022425_latestversion_v10.png", plot = forest_plot4b21, width = 10, height = 6, dpi = 300)


# Display the plot
print(forest_plot4b21)









