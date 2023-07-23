#!/usr/bin/python

import sys
from nltk import word_tokenize
from nltk.corpus import stopwords
from fuzzywuzzy import fuzz
import operator

def query_comparison_with_db(query_list,db_list):
    db_str = ' '.join(str(e) for e in db_list)
    query_str = ' '.join(str(e) for e in query_list)
    ratio=fuzz.ratio(query_str.lower(),db_str.lower())
    return ratio

def token_words_remove_stop_words(db_word):
    db_str_list = []	
    filtered_db = []
    eng_stop_words = stopwords.words('english')
    common_obs_stop_words = ["Cancer","cancer","Carcinoma","Tumor", "cell", "'s", "Syndrome", "disorder", "disease", "syndrome", "Cell", "Disorder", "Disease", "tumors","Cancerous","carcinoma","tumour","NOS",",","'" ]
    stop_words = eng_stop_words+common_obs_stop_words
    word_tokens1 = word_tokenize(db_word)
    filtered_db = [w1 for w1 in word_tokens1 if not w1 in stop_words]			
    return filtered_db		

try:
    text_file=open("../database/db.txt","r")
    line=text_file.read().split('\n') 
except IOError:
    print("File is not accessible")
      
db_tempdict = {}

query = sys.argv[1]
for db_wd in line:
    (key, val)=db_wd.split('\t')
    db_tempdict[key] = query_comparison_with_db(token_words_remove_stop_words(query),token_words_remove_stop_words(val))
    
max_path_val=max(db_tempdict.iteritems(), key=operator.itemgetter(1))

print query,"\t",max_path_val[0],"\t",max_path_val[1]
