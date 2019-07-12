library("sqldf")
library("dplyr")
library(tidyr)


setwd("C:/Users/henriquehashimoto/Downloads/drive-download-20190701T212918Z-001")
aug <- data.frame(readLines("access_log_Aug95"))
jul <- data.frame(readLines("access_log_Jul95"))


##Unindo ambos datasets
df <- sqldf("SELECT * FROM aug
              UNION ALL
            SELECT * FROM jul")

names(df) <- "Logs"



####################
## 1 - CONTANDO OS HOSTS
####################
hosts <- substr(df$Logs,1,regexpr(" ",df$Logs)-1)
length(unique(hosts))

#RESPOSTA: [1] 137979


####################
## 2- QUANTOS ERROS 404
####################
erros <- data.frame(substr(df$Logs, nchar(df$Logs)-4, nchar(df$Logs)))
names(erros) <- "Logs"
count(filter(erros,Logs == "404 -"))

#RESPOSTA: 20900


####################
# 3 - TOP 5 URL COM ERROS 404
####################
hostsLogs <- data.frame(cbind(hosts,erros))
sqldf("SELECT hosts, count(*) AS Total 
      FROM hostsLogs 
      WHERE Logs like '%404 -%'
      group by hosts order by 2 desc")


#                   hosts                 Total
#1                  hoohoo.ncsa.uiuc.edu   251
#2                  piweba3y.prodigy.com   157
#3           jbiagioni.npt.nuwc.navy.mil   132
#4                  piweba1y.prodigy.com   114
#5                  www-d4.proxy.aol.com    91








