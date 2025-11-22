# has_ticket = input("是否有车票（有或没有）：")
#
# if has_ticket == "有":
#     can_next = True
#     print("可以进行安检")
#     has_knife = input("有刀吗（有或没有）：")
#     if input_content == "有":
#         can_next2 = True
#         knife_length = int(input("刀长多少（有或没有）："))
#         if knife_length > 20 :
#             print("刀长超过20cm，不允许携带")
#         else:
#             print("刀长不超过20cm，可以上车")
#
#     else:
#         has_knife = False
#         print("可以上车")
# else:
#     has_ticket = False
#     print("没有车票，不能上车")
# age=53
# print(age>0 and age <120)
# python_score=int(input("Enter your pythonscore: "))
# c_score=int(input("Enter your cscore: "))
# if python_score >60 or c_score >60 :
#     print("成绩合格")
# else :
#     print("成绩不合格")
# import random
#
# while True:
#     me = input("请出拳，石头，剪刀，布：")
#     options = ['石头', '剪刀', '布']
#     com = random.choice(options)
#
#     if not (me == '石头' or me == '剪刀' or me == '布'):
#         print("输入不正确，请重新输入")
#     else:
#         break
#
# if me == '石头' and com == '剪刀' or me == '剪刀' and com == '布' or me == '布' and com == '石头':
#     print(f"电脑的出拳是{com}")
#     print("你赢了")
# elif me == '石头' and com == '布' or me == '布' and com == '剪刀' or me == '剪刀' and com == '石头':
#     print(f"电脑的出拳是{com}")
#     print("你输了")
# else:
#     print(f"电脑的出拳是{com}")
#     print("平局")
# i=0
# Sum=0
# while i<=100:
#     Sum = Sum + i
#     i+=1
# print(Sum)
# i = 0
# Sum = 0
# while i <=100:
#     Sum = Sum + i
#     i += 2
#
# print(Sum)
# i=1
# while i<=5:
#     print('* '*i)
#     i=i+1
# x=1
# while x<=5:
#     y=1
#     while y<=x:
#         print('*',end=' ')
#         y+=1
#     print()
#     x+=1
# from itertools import count
#
# x=1
# while x<=9:
#     y = 1
#     while y<=x:
#         print(f'{y}*{x}={x*y}',end='\t')
#         y=y+1
#     print()
#     x=x+1
# for row in range(1,10):
#     for col in range(1,row+1):
#         print(f'{col}*{row}={col*row}',end='\t')
# #     print()
# L=[1,2,3,4,121,222]
# l=('a','b','c')
# L.extend(l)
# print(L)
# s1 = 72
# s2 = 85
# R=(s2-s1)/s1
# print('成绩提升了 %.1f %%'%(R*100))
# s1 = 72
# s2 = 85
# r = ((s2 - s1) / s1 * 100)
# print('{:.1f}%'.format(r))
# Hight=1.75
# Weight=80.5
# BMI=Weight/(Hight*Hight)
# if BMI<18.5:
#     print("过轻")
# elif 25>BMI>18.5:
#     print("正常")
# elif 28>BMI>25:
#     print("肥胖")
# elif BMI>32:
#     print("严重肥胖")
# print(BMI)
# args = ['gcc', 'hello.c', 'world.c']
# # args = ['clean']
# # args = ['gcc']
#
# match args:
#     # 如果仅出现gcc，报错:
#     case ['gcc']:
#         print('gcc: missing source file(s).')
#     # 出现gcc，且至少指定了一个文件:
#     case ['gcc', file1, *files]:
#         print('gcc compile: ' + file1 + ', ' + ', '.join(files))
#     # 仅出现clean:
#     case ['clean']:
#         print('clean')
#     case _:
#         print('invalid command.')
# Name=['Bart', 'Lisa', 'Adam']
# for x in Name:
#     print(f'hello,{x}!')
# n1=255
# a=hex(n1)
# print(a)
# def my_abs(x):
#     if x > 0:
#         return x;
#     if x <0:
#         return -x;
# print(my_abs(-1))
# def my_abs(x):
#     if not isinstance(x,(int,float)):
#         raise TypeError('?')
#     if x<0:
#         return -x
#     if x>=0:
#         return x
# # print(my_abs(0))
# import math
# def move(x,y,step,angle=0):
#     nx=x+step*math.cos(angle)
#     ny=y+step*math.sin(angle)
#     return nx,ny
# print(move(1,0,10,math.pi/2))
# import math
#
# def quadratic(a, b, c):
#     delta = b**2 - 4*a*c
#     if delta < 0:
#         print("NONE")
#         return None, None
#     if delta == 0:
#         x=-b/(2*a)
#         return x,x
#     if delta > 0:
#         x1=(-b+math.sqrt(b*b-4*a*c))/(2*a)
#         x2=(-b-math.sqrt(b*b-4*a*c))/(2*a)
#         return x1,x2;
# x1,x2=quadratic(2,5,1)
# print(x1,x2)
# import math
#
# def sx(*numbers):
#     sum=0
#     for i in numbers:
#         sum=sum+i*i
#     return sum
# num=[1,2,3,4,5]
# print(sx(*num))
# from functools import reduce
# from platform import android_ver
# from functools import reduce
# from operator import index, concat
#
# from Bio.Data.CodonTable import standard_dna_table
# def regrest(name,age,**kw):
#     print('name:', name, 'age:', age, 'other:', kw)
# info={'hight':180,'weight':60}
# regrest('zhang',20,**info)
# def person(name, age, **kw):
#     if 'city' in kw:
#         # 有city参数
#         print(f"{name} 所在的城市是 {kw['city']}")
#     if 'job' in kw:
#         # 有job参数
#         pass
#     print('name:', name, 'age:', age, 'other:', kw)
# person('zhang', 18,city='shanghai')
# def person(name, age, *, city, job):
#     print(name, age, city, job)
# person('zhang',24,city=30,job='python')
# def person(name, age, *,city, job,**kw):
#     print(name, age, city, job,kw)
# person('zhang',23,city='beijing',job='python',like='wahaha')
# def person(name, age, *args, ):
#     print(name, age, args)
# person('Jack', 24, 'Beijing', 'Engineer')
# def f1(a, b, c=0, *args, **kw):
#     print('a =', a, 'b =', b, 'c =', c, 'args =', args, 'kw =', kw)
#
# def f2(a, b, c=0, *, d, **kw):
#     print('a =', a, 'b =', b, 'c =', c, 'd =', d, 'kw =', kw)
# args = (1, 2, 3)
# kw = {'d': 88,'f':99, 'x': '#'}
# f1(*args, **kw)
# def mul(*args):
#     result=1
#     for i in args:
#         result=result*i
#     return result
# x=mul(1,3,5,7)
# print(x)
# def fact(n):
#     if n==1:
#         return 1
#     return n * fact(n - 1)
# print(fact(1000))
# def move(n,a,b,c):
#     if n==1:
#         print(a,'-->',c)
#     else:
#         move(n-1,a,c,b)
#         print(a,'-->',c)
#         move(n-1,b,a,c)
# move(4,'A','B','C')
# L=[]
# for i in range(100):
#     if i%2==1:
#         L.append(i)
# print(L)
# L = [] # method 1
# for x in range(0,100):
#     if x % 2 == 0:
#         continue
#     L.append(x)
# print(L)
# def shan(l):
#     x = 0
#     while x < len(l) and l[x] == ' ':
#         x += 1
#     y = len(l) - 1
#     while y >= 0 and l[y] == ' ':
#         y -= 1
#     if x > y:
#         return ''
#     return l[x:y+1]
# d = {'a': 1, 'b': 2, 'c': 3}
# for key in d:
#     print(key)
# for i,value in enumerate(['A','B','C']):
#     print(i,value)
# def findMinAndMax(L):
#     if len(L)==0:
#         return [None,None]
#     if len(L)==1:
#         return [L[0],L[0]]
#     min_L=L[0]
#     max_L=L[0]
#     for i in range(len(L)):
#         if L[i] > max_L:
#             max_L=L[i]
#         if L[i] < min_L:
#             min_L=L[i]
#
#     return [min_L,max_L]
# print(findMinAndMax([1,2,3,4,5,6,7,8,9]))
# D={1:'A',2:'B',3:'C',4:'D',5:'E',6:'F'}
# ND=([str(k)+'='+v for k,v in D.items()])
# print([s.lower()for s in ND])
# L1 = ['Hello', 'World', 18, 'Apple', None]
# L2 =[s.lower() for s in L1  if isinstance(s, str) ]
# print(L2)
# L=[x for x in range(1,11)]
# g=(x for x in range(1,11))
# for i in g:
#     print(i)
# def fib(n_max):
#     n,a,b=0,0,1
#     while n<n_max:
#         yield b
#         a,b=b,a+b
#         n=n+1
#     return 'done'
# g=fib(10)
# while True:
#     try:
#         x=next(g)
#         print('g:',x)
#     except StopIteration as e:
#         print('Generator return value:',e.value)
#         break
# def triangles():
#     row=[1]
#     while True:
#         yield row
#         nextrow = [1]
#         for i in range(len(row)-1):
#             nextrow.append(row[i]+row[i+1])
#         nextrow.append(1)
#         row=nextrow
# def add(x, y, f):
#     return f(x) + f(y)
#
# print(add(-5, 6, abs))
# from functools import reduce
# N={'1':1,'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8}
# def str2int(s):
#     def trans1(x,y):
#         return x*10+y
#     def trans2(v):
#         return N[v]
#     return reduce(trans1,map(trans2,s))
# result = str2int('123')
# print(result)
# def normalize(n):
#     if n:
#         return n[0].upper()+n[1:].lower()
# L1 = ['adam', 'LISA', 'barT']
# L2 = list(map(normalize, L1))
# print(L2)
# from functools import reduce
#
# def prod(s):
#     def mutip(x, y):
#         return x * y
#     return reduce(mutip, s)
#
# print('3 * 5 * 7 * 9 =', prod([3, 5, 7, 9]))
# if prod([3, 5, 7, 9]) == 945:
#     print('测试成功!')
# else:
#     print('测试失败!')
# from functools import reduce
# def str2float(s):
#     FLOATS = {'0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9}
#     def trans1(s):
#         return FLOATS[s]
#     if '.' in s:
#         L = s.split('.')
#         intpart = L[0]
#         floatpart = L[1]
#         def trans2(x,y):
#             return x*10+y
#         return reduce(trans2, map(trans1,intpart))+reduce(trans2,map(trans1,floatpart))/(10 ** len(floatpart))
#     else:
#         return reduce(trans2, map(trans1, s))
# print('str2float(\'123.456\') =', str2float('123.456'))
# if abs(str2float('123.456') - 123.456) < 0.00001:
#     print('测试成功!')
# else:
#     print('测试失败!')
# def notK(s):
#     return s and s.strip()
# r=list(filter(notK, ['A', '', 'B', None, 'C', '  ']))
# print(r)
# def _odd_iter():
#     n = 1
#     while True:
#         n = n + 2
#         yield n
# def SS(n):
#     return lambda x:x%n>0
# def primes():
#     yield 2
#     it=_odd_iter()
#     while True:
#         n=next(it)
#         yield n
#         it=filter(SS(n),it)
# def sx(s):
#         return s==int(str(s)[::-1])
# t=list(filter(sx,range(1,1000)))
# print(t)
# L = [('Bob', 75), ('Adam', 92), ('Bart', 66), ('Lisa', 88)]
# def byname(t):
#     return t[0].lower()
# L2=sorted(L,key=byname)
# print(L2)
# def bysore(f):
#     return f[1]
# L3=sorted(L,key=bysore,reverse=True)
# print(L3)
# 找到 Matplotlib 的配置目录
# from Bio.Seq import Seq, reverse_complement, complement
#
# my_seq=Seq('ATCGATCGATCGATCGATCG')
# print("A COUNT is",my_seq.count("A"))
# print(len(my_seq))
# from Bio import SeqIO
# for seq_record in SeqIO.parse("ls_orchid.fasta","fasta"):
#     print(seq_record.id)
#     print(repr(seq_record.seq))
#     print(len(seq_record))
# import numpy as np
# import pandas as pd
# from fontTools.misc.bezierTools import splitCubic
# from fontTools.misc.cython import returns

# s=pd.Series([1,2,4,np.nan,6,8])
# time=pd.date_range('20230201', periods=6,freq='D')
# df = pd.DataFrame(np.random.randn(6, 4), index=time, columns=list("ABCD"))
# df2=pd.DataFrame(
#     {
#         "A":1.0,
#         "B":pd.Timestamp("20250201"),
#         "C":pd.Series(1,index=range(4),dtype='float32'),
#         "D":np.array([3]*4,dtype='int32'),
#         "E":pd.Categorical(['test','train','test','train']),
#         "F":"foo"
#     }
# )
# df2=df.copy()
# df2.loc[:,"E"]=["one","two","three","four","five","six"]
# print(df2)
# dates=pd.date_range("20250201",periods=6)
# s1=pd.DataFrame(np.random.randn(6, 4), index=dates, columns=list("ABCD"))
# s1.at[dates[0], "A"] = 0
# s1.iat[0,1]=0
# s1.loc[:,"D"]=np.array([666]*len(s1))
# s1[s1>0]=-s1
# print(s1)
# dates=pd.date_range('20230201', periods=6,freq='D')
# df = pd.DataFrame(np.random.randn(6, 4), index=dates, columns=list("ABCD"))
# s = pd.Series([1, 3, 5, np.nan, 6, 8], index=dates).shift(2)
# s1=pd.Series(np.random.randint(0,7,size=10))
# df_sub=df.sub(s, axis="index")
# df_agg=df.agg(lambda x:np.mean(x)*5.6)
# df_trans=df.transform(lambda x: x*101.2)
# s2=pd.Series(["A","B","C","D","HAHA",np.nan,"dog"])
# print(s2.str.lower())
# df=pd.DataFrame(np.random.randn(10,4))
# df_p=[df[:3],df[3:7],df[7:]]
# df_concat=pd.concat(df_p)
# print(df_concat)
# left=pd.DataFrame({"key":["foo","bar"],"lval":[1,2]})
# right=pd.DataFrame({"key":["foo","bar"],"rval":[4,5]})
# pd_merge=pd.merge(left,right,on="key")
# print(pd_merge)
# df=pd.DataFrame(
#     {"A":["foo","bar","foo","bar","foo","bar","foo","foo"],
#      "B":["one","one","two","three","two","two","one","three"],
#      "C":np.random.randn(8),
#      "D":np.random.randn(8),
#      }
# )
# df_sum=df.groupby("A")[["C","D"]].sum()
# df_sum2=df.groupby(["A", "B"]).sum()
# print(df_sum2)
# arrays=[
#     ["bar","bar","baz","baz","foo","foo","qux","qux"],
#     ["one","two","one","two","one","two","one","two"],
# ]
# index=pd.MultiIndex.from_arrays(arrays,names=['frist','second'])
# df=pd.DataFrame(np.random.randn(8,2),index=index,columns=["A","B"])
#
# print((df.stack(future_stack=True)).unstack(2))
# df=pd.DataFrame(
#     {"A":["one","one","two","three"]*3,
#      "B":["A","B","C"]*4,
#      "C":["foo","foo","foo","bar","bar","bar"]*2,
#      "D":np.random.randn(12),
#      "E":np.random.randn(12),}
#                 )
# df2=pd.pivot_table(df,values="D",index=["A","B"],columns=["C"])
# print(df,df2)
# rng=pd.date_range('01/01/2025', periods=5, freq='D')
# ts=pd.Series(np.random.randn(len(rng)), rng)
# ts_utc=ts.tz_localize("UTC")
# print(rng+pd.offsets.BusinessDay(5))
# df=pd.DataFrame({"id":[1,2,3,4,5,6],"raw_grade":["a","b","b","a","a","e" ]              })
# df["grade"]=df["raw_grade"].astype("category")
# new_categories = ["very good", "good", "very bad"]
# df["grade"]=df["grade"].cat.rename_categories(new_categories)
# new2_categories = ["very bad", "bad", "medium","good","very good"]
# df["grade"]=df["grade"].cat.set_categories(new2_categories)
# print(df.groupby("grade",observed=False).size())
# import matplotlib.pyplot as plt
# df=pd.DataFrame(np.random.randn(1000,4),
#                 index=pd.date_range('1/1/2025',periods=1000),
#                 columns=["A","B","C","D"])
# df=df.cumsum();
# plt.figure();
# df.plot();
# plt.legend(loc='best')
# plt.show()
#
# df1=pd.read_excel('E:/桌面/武汉数据/学习/11.12.xlsx',"sheet1",index_col=0,na_values='NA')
# from Bio import SeqIO,Entrez
# Entrez.email='2653578963@qq.com'
# id="NC_006853.1"
# handle=Entrez.efetch(db='nucleotide', id=id, rettype="fasta",retmode='txt')
# record=SeqIO.read(handle,'fasta')
# print(f"length:{len(record.seq)}bp")
# protein=record.seq.translate()
# print(len(protein))
# from Bio import SeqIO
# from Bio.Align import PairwiseAligner
# from Bio.Align import MultipleSeqAlignment
# from Bio.SeqRecord import SeqRecord
# from Bio.Seq import Seq
#
# # 参考序列文件路径
# reference_file = "P1R.txt"
#
# # 样本序列文件路径列表
# sample_files = [f"P1{A}.seq" for A in "ABCDE"]
#
# # 读取参考序列
# try:
#     with open(reference_file, 'r') as f:
#         reference_seq_str = f.read().strip()
#     reference_record = SeqRecord(Seq(reference_seq_str), id="P1R")
#     reference_sequence = reference_record.seq
# except FileNotFoundError:
#     print(f"未找到参考序列文件: {reference_file}")
#     exit(1)
#
# # 创建比对器对象
# aligner = PairwiseAligner()
#
# # 设置比对的参数
# aligner.mode = 'global'
# aligner.match_score = 1
# aligner.mismatch_score = -1
# aligner.open_gap_score = -1
# aligner.extend_gap_score = -0.5
#
# # 创建一个空的多序列比对对象
# msa = MultipleSeqAlignment([])
#
# # 依次将每个样本序列与参考序列进行比对，并添加到多序列比对对象中
# for sample_file in sample_files:
#     try:
#         with open(sample_file, 'r') as f:
#             sample_seq_str = f.read().strip()
#         sample_record = SeqRecord(Seq(sample_seq_str), id=sample_file)
#         sample_sequence = sample_record.seq
#         alignments = aligner.align(reference_sequence, sample_sequence)
#         best_alignment = next(alignments)  # 取得分最高的比对结果
#         # 获取比对后的样本序列
#         aligned_sample_seq = str(best_alignment.target)
#         aligned_reference_seq = str(best_alignment.query)
#         sample_record.seq = aligned_sample_seq
#         msa.append(sample_record)
#
#         # 找出突变位点
#         mutations = []
#         for i in range(len(aligned_reference_seq)):
#             ref_base = aligned_reference_seq[i]
#             alt_base = aligned_sample_seq[i]
#             # 排除空位
#             if ref_base != '-' and alt_base != '-' and ref_base != alt_base:
#                 mutations.append((i + 1, ref_base, alt_base))
#
#         if mutations:
#             print(f"样本 {sample_file} 的突变位点：")
#             for pos, ref_base, alt_base in mutations:
#                 print(f"位置 {pos}: {ref_base} -> {alt_base}")
#         else:
#             print(f"样本 {sample_file} 未发现突变。")
#
#         # 打印比对详细信息
#         print(f"样本 {sample_file} 比对信息：")
#         print(aligned_reference_seq)
#         print(aligned_sample_seq)
#
#     except FileNotFoundError:
#         print(f"未找到样本序列文件: {sample_file}")
#     except ValueError:
#         print(f"无法读取样本序列文件: {sample_file}，请检查文件格式是否正确。")
#
# # 添加参考序列到多序列比对结果中
# msa.append(reference_record)
#
# # 输出多序列比对结果
# for record in msa:
#     print(record.id)
#     print(record.seq)
# import numpy as np
# mat1=np.array([
#     [1,2,3,4],
#     [5,6,7,8],
#     [9,10,11,12]
# ])
# mat2=np.array([
#     [2,3,4,5],
#     [4,5,6,7],
#     [6,7,8,9]
# ])
# ji=mat1*mat2
# print(ji)
# def romanToInt(s):
#     nums={"I":1,"V":5,"X":10,"L":50,"C":100,"D":500,"M":1000}
#     Sum=0
#     i=0
#     while i<len(s):
#         if  i+1 <len(s) and nums[s[i]]<nums[s[i+1]]:
#             Sum += nums[s[i + 1]] - nums[s[i]]
#             i+=2
#         else:
#             Sum+=nums[s[i]]
#             i+=1
#     return Sum
# 批量下载多品种牛线粒体序列（西藏牛/威宁牛等）
# 从 Bio 库中导入 Entrez 和 SeqIO 模块
# Entrez 模块用于与 NCBI 的 Entrez 数据库进行交互，可实现数据的搜索和下载
# SeqIO 模块用于处理生物序列文件的输入和输出
# from Bio import Entrez, SeqIO
# # 导入 os 模块，该模块提供了与操作系统进行交互的功能，可用于处理文件路径和目录
# import os
#
# from statsmodels.sandbox.regression.ols_anova_original import names

# 设置你的 NCBI 邮箱地址，这是使用 NCBI Entrez API 的要求
# 当你的请求对 NCBI 服务器造成较大压力时，他们可能会通过此邮箱联系你
# Entrez.email = "2653578963@qq.com"
# # 定义一个包含多个牛线粒体序列 ID 的列表，这些 ID 可用于从 NCBI 数据库中获取对应的序列
# species_ids = ["NC_001567", "NC_006853", "GQ351234"]  # 牛线粒体ID示例
#
# # 定义一个名为 fetch_sequences 的函数，用于批量获取并保存指定 ID 的生物序列
# # ids 参数是一个包含序列 ID 的列表
# # save_path 参数是指定的序列保存路径
# def fetch_sequences(ids, save_path):
#     # 初始化一个空列表，用于存储从 NCBI 下载的序列记录
#     sequences = []
#     # 检查指定的保存路径是否存在
#     # os.path.exists(save_path) 用于判断路径是否存在，返回布尔值
#     if not os.path.exists(save_path):
#         # 如果路径不存在，则使用 os.makedirs 函数创建该路径
#         # 此函数会递归创建所有必要的目录
#         os.makedirs(save_path)
#     # 遍历传入的序列 ID 列表
#     for id in ids:
#         try:
#             # 使用 Entrez.efetch 函数从 NCBI 的 nucleotide 数据库中获取指定 ID 的序列
#             # db="nucleotide" 表示使用核苷酸数据库
#             # id=id 指定要获取的序列 ID
#             # rettype="fasta" 表示以 FASTA 格式返回序列
#             handle = Entrez.efetch(db="nucleotide", id=id, rettype="fasta")
#             # 使用 SeqIO.read 函数读取从 NCBI 获取的序列数据
#             # handle 是 Entrez.efetch 返回的文件句柄
#             # "fasta" 表示读取的文件格式为 FASTA
#             record = SeqIO.read(handle, "fasta")
#             # 将读取到的序列记录添加到 sequences 列表中
#             sequences.append(record)
#             # 构建完整的文件保存路径，将保存目录和文件名组合在一起
#             # os.path.join 函数会根据操作系统自动处理路径分隔符
#             # f"{id}.fasta" 是使用 f-string 生成的文件名，以序列 ID 命名并加上 .fasta 扩展名
#             file_path = os.path.join(save_path, f"{id}.fasta")
#             # 使用 SeqIO.write 函数将序列记录保存到指定的文件中
#             # record 是要保存的序列记录
#             # file_path 是保存文件的路径
#             # "fasta" 表示保存的文件格式为 FASTA
#             SeqIO.write(record, file_path, "fasta")
#         # 捕获在获取序列过程中可能出现的异常
#         except Exception as e:
#             # 打印出错信息，包括出错的序列 ID 和具体的错误信息
#             print(f"获取序列 {id} 时出错: {e}")
#     # 返回存储所有下载序列记录的列表
#     return sequences
#
# # 定义一个名为 calculate_gc 的函数，用于计算给定序列的 GC 含量
# # sequence 参数是一个 BioPython 的 SeqRecord 对象，表示一个生物序列
# def calculate_gc(sequence):
#     # 计算序列中 G（鸟嘌呤）和 C（胞嘧啶）的总数
#     # sequence.seq 表示序列的具体碱基序列
#     # count("G") 和 count("C") 分别统计序列中 G 和 C 的出现次数
#     gc_count = sequence.seq.count("G") + sequence.seq.count("C")
#     # 计算 GC 含量的百分比
#     # len(sequence.seq) 表示序列的总长度
#     # 将 GC 总数除以序列总长度并乘以 100，得到 GC 含量的百分比
#     return gc_count / len(sequence.seq) * 100
#
# # 指定序列保存的路径
# save_path = "E:/桌面/武汉数据/学习/"
# # 调用 fetch_sequences 函数，传入序列 ID 列表和保存路径
# # 函数会返回一个包含所有下载序列记录的列表，并将其赋值给 sequences 变量
# sequences = fetch_sequences(species_ids, save_path)
#
# # 遍历下载的序列记录列表
# for sequence in sequences:
#     # 调用 calculate_gc 函数计算当前序列的 GC 含量
#     # 将计算结果赋值给 gc_content 变量
#     gc_content = calculate_gc(sequence)
#     # 打印每个序列的 ID 和对应的 GC 含量，保留两位小数
#     # 使用 f-string 格式化输出，: .2f 表示保留两位小数
#     print(f"序列 {sequence.id} 的 GC 含量: {gc_content:.2f}%")

# import subprocess
# from Bio import SeqIO
# import pandas as pd
# import numpy as np
# from scipy.spatial.distance import pdist, squareform
# from scipy.cluster.hierarchy import linkage, dendrogram
# import matplotlib.pyplot as plt
# import seaborn as sns
# from sklearn.preprocessing import OneHotEncoder
# import os
#
# # 第一步：合并多个 FASTA 文件
# files_path = "E:\桌面\武汉数据\学习"  # 替换为实际的文件路径
# files = [os.path.join(files_path, file) for file in os.listdir(files_path) if file.endswith('.fasta')]
# input_file = "combined.fasta"
#
# with open(input_file, 'w') as outfile:
#     for fasta_file in files:
#         with open(fasta_file, 'r') as infile:
#             outfile.write(infile.read())
#
# # 检查合并后的文件是否存在
# if not os.path.exists(input_file):
#     print(f"合并后的文件 {input_file} 不存在，请检查文件路径和合并操作。")
#     exit(1)
#
# # 提示手动进行比对
# print("请手动使用 MEGA 对 combined.fasta 文件进行比对，并将结果保存为 aligned.fasta 文件。")
# input("完成后按回车键继续...")
#
# # 第四步：读取比对后的序列
# output_file = "aligned.fas"
# if not os.path.exists(output_file):
#     print(f"未找到 {output_file} 文件，请确保你已完成手动比对并保存了结果。")
#     exit(1)
#
# # 尝试将 .meg 文件当作 FASTA 文件来读取
# aligned_records = list(SeqIO.parse(output_file, "fasta"))
# df = pd.DataFrame({
#     '品种': [record.id for record in aligned_records],
#     '序列': [str(record.seq) for record in aligned_records]
# })
#
# # 第五步：计算遗传多样性指标
# # 单倍型多样性（Hd）
# haplotype_count = df['序列'].nunique()
# Hd = (haplotype_count / len(df)) * (1 - (haplotype_count / len(df)))
#
#
# # 核苷酸多样性（π）
# def calculate_pi(sequences):
#     n = len(sequences)
#     L = len(sequences[0])
#     pi = 0.0
#     for i in range(n):
#         for j in range(i + 1, n):
#             diff = sum(1 for a, b in zip(sequences[i], sequences[j]) if a != b)
#             pi += diff / L
#     return pi * 2 / (n * (n - 1))
#
#
# pi = calculate_pi(df['序列'].tolist())
#
# # SNP 数量统计
# alignment_matrix = np.array([list(seq) for seq in df['序列']])
# snp_count = (alignment_matrix != alignment_matrix[0]).sum()
#
# # 第六步：生成多样性报告
# report = pd.DataFrame({
#     '指标': ['单倍型多样性', '核苷酸多样性', 'SNP 数量'],
#     '值': [Hd, pi, snp_count],
#     '解释': [
#         '不同单倍型的比例',
#         '平均核苷酸差异数',
#         '群体中多态位点的总数'
#     ]
# })
#
# # 保存为 CSV
# report.to_csv('牛种群遗传多样性报告.csv', index=False)
#
# # 第七步：可视化辅助分析
# # 种群间遗传距离树状图
# all_sequences = df['序列'].tolist()
# encoder = OneHotEncoder(handle_unknown='ignore')
# onehot = encoder.fit_transform([list(s) for s in all_sequences]).toarray()
# dist_matrix = pdist(onehot, metric='hamming')
# Z = linkage(dist_matrix, method='average')
# plt.figure(figsize=(10, 5))
# dendrogram(Z, labels=df['品种'], orientation='top')
# plt.title('牛种群遗传关系树')
# plt.show()
#
# # 变异位点热图
# plt.figure(figsize=(12, 4))
# sns.heatmap(alignment_matrix.T, cmap='viridis', yticklabels=False)
# plt.title('线粒体基因组变异位点分布')
# plt.show()
# def parse_clstr(file_path):
#     clusters = []
#     current_cluster = set()
#     try:
#         with open(file_path, 'r') as f:
#             for line in f:
#                 line = line.strip()
#                 if line.startswith('>Cluster'):
#                     if current_cluster:
#                         clusters.append(current_cluster)
#                         current_cluster = set()
#                 else:
#                     parts = line.split('>')
#                     if len(parts) >= 2:
#                         seq_id = parts[1].split('...')[0]
#                         sample = seq_id.split('_')[0]
#                         current_cluster.add(sample)
#         if current_cluster:
#             clusters.append(current_cluster)
#     except FileNotFoundError:
#         print(f"文件 {file_path} 未找到。")
#     except Exception as e:
#         print(f"发生未知错误: {e}")
#     return clusters
#
#
# import itertools
#
# # 解析聚类文件
# clusters = parse_clstr('E:/Data/clustered_genes.clstr')
#
# # 定义样本列表
# samples = [f'Ecoli_{i}' for i in range(1, 6)]
# core_pan = []
#
# for k in range(1, 6):
#     combinations = list(itertools.combinations(samples, k))
#     total_core, total_pan = 0, 0
#     for combo in combinations:
#         combo_set = set(combo)
#         core = sum(1 for cluster in clusters if combo_set.issubset(cluster))
#         pan = sum(1 for cluster in clusters if not combo_set.isdisjoint(cluster))
#         total_core += core
#         total_pan += pan
#     try:
#         avg_core = total_core / len(combinations)
#         avg_pan = total_pan / len(combinations)
#         core_pan.append((k, avg_core, avg_pan))
#     except ZeroDivisionError:
#         print(f"当 k = {k} 时，组合数量为 0，无法计算平均值。")
#
# # 输出结果
# for k, core, pan in core_pan:
#     print(f'Samples: {k}, Core: {core:.1f}, Pan: {pan:.1f}')
# def parse_clstr(file_path):
#     clusters = []
#     current_cluster = set()
#     try:
#         with open(file_path, 'r') as f:
#             for line in f:
#                 line = line.strip()
#                 if line.startswith('>Cluster'):
#                     if current_cluster:
#                         clusters.append(current_cluster)
#                         current_cluster = set()
#                 else:
#                     parts = line.split('>')
#                     if len(parts) >= 2:
#                         seq_id = parts[1].split('...')[0]
#                         sample = seq_id.split('_')[0]
#                         current_cluster.add(sample)
#         if current_cluster:
#             clusters.append(current_cluster)
#     except FileNotFoundError:
#         print(f"文件 {file_path} 未找到。")
#     except Exception as e:
#         print(f"发生未知错误: {e}")
#     return clusters
#
#
# import itertools
#
# # 样本名称
# samples = ['LIHDBMIF', 'DHKDBCCC', 'LEIKEONI', 'PKBHPNHA', 'PICPPNBC']
# clusters = parse_clstr('E:/Data/clustered_genes.clstr')
#
# core_pan = []
# for k in range(1, 6):
#     combinations = list(itertools.combinations(samples, k))
#     total_core, total_pan = 0, 0
#     for combo in combinations:
#         combo_set = set(combo)
#         core = sum(1 for cluster in clusters if combo_set.issubset(cluster))
#         pan = sum(1 for cluster in clusters if not combo_set.isdisjoint(cluster))
#         total_core += core
#         total_pan += pan
#     try:
#         avg_core = total_core / len(combinations)
#         avg_pan = total_pan / len(combinations)
#         core_pan.append((k, avg_core, avg_pan))
#     except ZeroDivisionError:
#         print(f"当 k = {k} 时，组合数量为 0，无法计算平均值。")
#
# # 输出结果
# for k, core, pan in core_pan:
#     print(f'Samples: {k}, Core: {core:.1f}, Pan: {pan:.1f}')
# import matplotlib.pyplot as plt
#
# k_values = [x[0] for x in core_pan]
# core_values = [x[1] for x in core_pan]
# pan_values = [x[2] for x in core_pan]
#
# plt.plot(k_values, core_values, marker='o', label='Core Genome')
# plt.plot(k_values, pan_values, marker='o', label='Pan Genome')
# plt.xlabel('Number of Samples')
# plt.ylabel('Number of Genes')
# plt.legend()
# plt.title('Core-Pan Genome Curve')
# plt.show()
# import pandas as pd
# import plotly.graph_objects as go
# from plotly.subplots import make_subplots
# import numpy as np
#
# # 1. 读取并预处理数据
# file_path = r"E:\桌面\武汉数据\乌珠穆沁白牛项目\sample109.population_evolution\result\08.Sweep\03.fst_pi_stat\UW_vs_Mo-OD\enrich.UW_vs_Mo-OD.UW\KEGG\UW_vs_Mo-OD.UW.kegg_rich.xls"
# df = pd.read_csv(file_path, sep="\t", dtype=str)
#
# # 转为数值并筛选
# df['p.adjust'] = df['p.adjust'].astype(float)
# top_paths = (
#     df.sort_values('p.adjust')
#       .drop_duplicates('Description', keep='first')
#       .head(15)['Description']
#       .tolist()
# )
# sig = df[df['Description'].isin(top_paths)].copy()
#
# # 3. 构造通路的点图数据
# # 我们用 –log10(p.adjust) 作为点的大小指标
# path_stats = (
#     df[df['Description'].isin(top_paths)]
#     .drop_duplicates('Description', keep='first')
#     .set_index('Description')
#     [['Count', 'p.adjust']]
#     .assign(logP=lambda d: -np.log10(d['p.adjust'].astype(float)))
# )
#
# # 简化标签（示例）
# sig['gene'] = sig['geneID'].apply(lambda x: x[:8] + '...' if len(x) > 10 else x)
# sig['Description'] = sig['Description'].apply(lambda x: x[:15] + '...' if len(x) > 20 else x)
#
# # 拆基因，多行
# sig = sig.assign(gene=sig['gene'].str.split('/')).explode('gene')
# sig = sig.groupby('Description').head(5)  # 每通路保留最多5基因
#
# # 2. 构造 Sankey 的 nodes/links
# pathways = sig['Description'].unique().tolist()
#
# # 基因按连接数排序
# gene_connection_count = sig.groupby('gene').size().sort_values(ascending=False)
# genes = gene_connection_count.index.tolist()
#
# nodes = genes + pathways  # 基因放左侧（index 0~），通路放右侧（index len(genes)~）
#
# link_df = (
#     sig.groupby(['gene', 'Description'])
#        .size()
#        .reset_index(name='value')
# )
# link_df['source'] = link_df['gene'].map(lambda g: genes.index(g))
# link_df['target'] = link_df['Description'].map(lambda p: pathways.index(p) + len(genes))
#
# # 4. 创建子图：1 行 2 列，宽度比例 0.6/0.4
# fig = make_subplots(
#     rows=1, cols=2,
#     column_widths=[0.6, 0.4],
#     specs=[[{"type": "sankey"}, {"type": "scatter"}]]
# )
#
# # 5. 添加 Sankey 图
# fig.add_trace(go.Sankey(
#     node=dict(
#         label=nodes,
#         pad=20,
#         thickness=12,
#         line=dict(color="black", width=0.5),
#         x=[0] * len(genes) + [1] * len(pathways),  # 左 0，右 1
#         y=(list(np.linspace(0, 1, len(genes))) + list(np.linspace(0, 1, len(pathways))))
#     ),
#     link=dict(
#         source=link_df['source'],
#         target=link_df['target'],
#         value=link_df['value'],
#         color="rgba(128, 128, 128, 0.6)",  # 浅灰透明线条
#         hovertemplate='Gene: %{source.label}<br>Pathway: %{target.label}<br>Count: %{value}<extra></extra>'
#     )
# ), row=1, col=1)
#
# # 6. 添加右侧点图
# fig.add_trace(go.Scatter(
#     x=path_stats['logP'],
#     y=path_stats.index,
#     mode='markers',
#     marker=dict(
#         size=path_stats['Count'].astype(int),  # 点大小与基因计数成正比
#         sizemode='area',
#         sizeref=2. * max(path_stats['Count'].astype(int)) / (40. ** 2),
#         sizemin=4,
#         color=path_stats['logP'],  # 颜色根据 p.adjust 调整
#         colorbar=dict(title='-log10(p.adjust)'),
#         showscale=True
#     ),
#     hovertemplate=
#     'Pathway: %{y}<br>' +
#     'Gene Count: %{marker.size}<br>' +
#     '-log10(p.adjust): %{x:.2f}<extra></extra>'
# ), row=1, col=2)
#
# # 7. 布局调整
# fig.update_layout(
#     title_text="KEGG 富集：基因–通路 Sankey + 通路显著性 Dot Plot",
#     font_size=12,
#     margin=dict(l=20, r=20, t=60, b=20)
# )
#
# fig.show()





# import pandas as pd
# import plotly.graph_objects as go
# from plotly.subplots import make_subplots
# import numpy as np
#
# # 1. 读取并预处理数据
# file_path = r"E:\桌面\武汉数据\乌珠穆沁白牛项目\sample109.population_evolution\result\08.Sweep\03.fst_pi_stat\UW_vs_Mo-OD\enrich.UW_vs_Mo-OD.UW\KEGG\UW_vs_Mo-OD.UW.kegg_rich.xls"
# df = pd.read_csv(file_path, sep="\t", dtype=str)
#
# # 转为数值并筛选
# df['p.adjust'] = df['p.adjust'].astype(float)
# top_paths = (
#     df.sort_values('p.adjust')
#       .drop_duplicates('Description', keep='first')
#       .head(15)['Description']
#       .tolist()
# )
# sig = df[df['Description'].isin(top_paths)].copy()
#
# # 3. 构造通路的点图数据
# # Gene Ratio作为横轴，-log10(corrected p-value)作为纵轴
# path_stats = (
#     df[df['Description'].isin(top_paths)]
#     .drop_duplicates('Description', keep='first')
#     .set_index('Description')
#     [['GeneRatio', 'p.adjust']]
#     .assign(logP=lambda d: -np.log10(d['p.adjust'].astype(float)))
# )
#
# # Gene Ratio的点图横轴（值需要转化为浮动数字类型）
# path_stats['GeneRatio'] = path_stats['GeneRatio'].apply(lambda x: float(x.split('/')[0]) / float(x.split('/')[1]) if '/' in x else 0)
#
# # 简化标签（示例）
# sig['gene'] = sig['geneID'].apply(lambda x: x[:8] + '...' if len(x) > 10 else x)
# sig['Description'] = sig['Description'].apply(lambda x: x[:15] + '...' if len(x) > 20 else x)
#
# # 拆基因，多行
# sig = sig.assign(gene=sig['gene'].str.split('/')).explode('gene')
# sig = sig.groupby('Description').head(5)  # 每通路保留最多5基因
#
# # 2. 构造 Sankey 的 nodes/links
# pathways = sig['Description'].unique().tolist()
#
# # 基因按连接数排序
# gene_connection_count = sig.groupby('gene').size().sort_values(ascending=False)
# genes = gene_connection_count.index.tolist()
#
# nodes = genes + pathways  # 基因放左侧（index 0~），通路放右侧（index len(genes)~）
#
# link_df = (
#     sig.groupby(['gene', 'Description'])
#        .size()
#        .reset_index(name='value')
# )
# link_df['source'] = link_df['gene'].map(lambda g: genes.index(g))
# link_df['target'] = link_df['Description'].map(lambda p: pathways.index(p) + len(genes))
#
# # 4. 创建子图：1 行 2 列，宽度比例 0.6/0.4
# fig = make_subplots(
#     rows=1, cols=2,
#     column_widths=[0.6, 0.4],
#     specs=[[{"type": "sankey"}, {"type": "scatter"}]]
# )
#
# # 5. 添加 Sankey 图
# fig.add_trace(go.Sankey(
#     node=dict(
#         label=nodes,
#         pad=20,
#         thickness=12,
#         line=dict(color="black", width=0.5),
#         x=[0] * len(genes) + [1] * len(pathways),  # 左 0，右 1
#         y=(list(np.linspace(0, 1, len(genes))) + list(np.linspace(0, 1, len(pathways))))
#     ),
#     link=dict(
#         source=link_df['source'],
#         target=link_df['target'],
#         value=link_df['value'],
#         color="rgba(128, 128, 128, 0.6)",  # 浅灰透明线条
#         hovertemplate='Gene: %{source.label}<br>Pathway: %{target.label}<br>Count: %{value}<extra></extra>'
#     )
# ), row=1, col=1)
#
# # 6. 添加右侧点图，调整横纵轴
# fig.add_trace(go.Scatter(
#     x=path_stats['GeneRatio'],  # 横轴改为GeneRatio
#     y=path_stats['logP'],  # 纵轴改为-log10(corrected p-value)
#     mode='markers',
#     marker=dict(
#         size=path_stats['GeneRatio'] ,  # 将点的大小调小
#         sizemode='area',
#         sizeref=2. * max(path_stats['GeneRatio']) / (40. ** 2),
#         sizemin=4,  # 最小点大小
#         color=path_stats['logP'],  # 颜色根据-log10(p.adjust)调整
#         colorscale='Viridis',  # 使用更鲜艳的配色
#         colorbar=dict(title='-log10(p.adjust)'),
#         showscale=True
#     ),
#     hovertemplate=
#     'Pathway: %{y}<br>' +
#     'Gene Ratio: %{x:.3f}<br>' +
#     '-log10(p.adjust): %{marker.color:.2f}<extra></extra>'
# ), row=1, col=2)
#
# # 7. 布局调整
# fig.update_layout(
#     title_text="KEGG 富集：基因–通路 Sankey + 通路显著性 Dot Plot",
#     font_size=12,
#     margin=dict(l=20, r=20, t=60, b=20),
#     showlegend=False  # 去除图例，避免杂乱
# )
#
# fig.show()
# fig.write_image("pic.png")
# import geopandas as gpd
# import matplotlib.pyplot as plt
#
# world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))
#
# fig, ax = plt.subplots(figsize=(10, 6))
# world.plot(ax=ax, color='lightgray', edgecolor='black')
#
# # 示例点
# sample_points = gpd.GeoDataFrame(
#     geometry=gpd.points_from_xy([116.4, 118.1], [39.9, 36.2]),
#     crs="EPSG:4326"
# )
# sample_points.plot(ax=ax, color='red')
#
# plt.xlim(100, 130)
# plt.ylim(30, 45)
# plt.show()
# import pandas as pd
# import seaborn as sns
# import matplotlib.pyplot as plt
#
# # 1. 数据 ------------------------------------------------------------------
# group_map = {
#     '对照组1': [6.1982, 5.0833, 6.4203],
#     '对照组2': [5.8420, 5.2161, 3.2804],
#     '对照组3': [9.4330, 10.5522, 10.4011],
#     '实验组1': [9.3292, 6.5347, 10.5461],
#     '实验组2': [4.6651, 7.1511, 7.0251],
#     '实验组3': [6.1580, 7.3218, 9.1440]
# }
#
# # 2. 计算 ΔΔCt 与 RQ -------------------------------------------------------
# ref_mean = pd.Series(group_map['对照组1']).mean()
# df = []
# for g, vals in group_map.items():
#     vals = pd.Series(vals)
#     ddct = vals - ref_mean
#     rq = 2 ** (-ddct)
#     df.append(pd.DataFrame({
#         'Group': g,
#         'ΔΔCt': ddct,
#         'RQ': rq
#     }))
# df = pd.concat(df, ignore_index=True)
#
# # 3. 绘图 ------------------------------------------------------------------
# plt.rcParams['font.family'] = 'SimHei'  # 支持中文显示（根据需要调整）
# plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题
# fig, ax = plt.subplots(1, 2, figsize=(12, 4), dpi=120)
#
# # 3.1 ΔΔCt 图
# sns.barplot(
#     data=df,
#     x='Group',
#     y='ΔΔCt',
#     errorbar='sd',  # 显示标准差
#     ax=ax[0],
#     palette='Set2',
#     hue='Group',
#     legend=False
# )
# ax[0].set_title('ΔΔCt (均值 ± 标准差)')
# ax[0].axhline(0, ls='--', c='grey')  # 参考线（对照组1的均值）
# ax[0].set_xlabel('')  # 去除x轴标签
#
# # 3.2 RQ 图（补充第二个子图）
# sns.barplot(
#     data=df,
#     x='Group',
#     y='RQ',
#     errorbar='sd',
#     ax=ax[1],
#     palette='Set2',
#     hue='Group',
#     legend=False
# )
# ax[1].set_title('相对表达量 RQ (均值 ± 标准差)')
# ax[1].axhline(1, ls='--', c='grey')  # RQ=1表示与对照组1表达量相同
# ax[1].set_xlabel('')
#
# # 显示图像（关键：没有这行代码，图像不会显示）
# plt.tight_layout()  # 自动调整布局，避免标签重叠
# plt.show()
# import pandas as pd
# import matplotlib.pyplot as plt
#
# # 数据输入
# data = {
#     'Group': ['NC1']*3 + ['NC2']*3 + ['NC3']*2 + ['AR1']*3 + ['AR2']*3 + ['AR3']*3,
#     'RQ': [0.385113488, 0.202102007, 0.554921481,
#            2.705050552, 0.319958247, 0.160267695,
#            3.493457419, 0.71939476,
#            0.055071723, 0.512617827, 0.016654497,
#            0.000978633, 0.000712242, 0.002950517,
#            0.0040797, 0.003156531, 0.003005276]
# }
#
# df = pd.DataFrame(data)
#
# # 计算均值与标准误
# summary = df.groupby('Group')['RQ'].agg(['mean', 'sem']).reset_index()
#
# # 绘制柱状图
# plt.figure(figsize=(8,6))
# bars = plt.bar(summary['Group'], summary['mean'], yerr=summary['sem'], capsize=5,
#                color=['#A0C4FF']*3 + ['#FFADAD']*3, edgecolor='black')
#
# plt.ylabel('METTL1 Gene Expression (RQ)', fontsize=12)
# plt.xlabel('Group', fontsize=12)
# plt.title('METTL1 Expression Levels in NC and AR Groups', fontsize=14)
# plt.tight_layout()
# plt.savefig('E:/桌面/小欣/免疫组化/1.png', dpi=300, bbox_inches='tight')
# plt.show()
# import pandas as pd
# import matplotlib.pyplot as plt
#
# # 数据输入（根据你提供的表格）
# data = {
#     'Group': ['NC1']*3 + ['NC2']*3 + ['NC3']*2 + ['AR1']*3 + ['AR2']*3 + ['AR3']*3,
#     'RQ': [0.385113488, 0.202102007, 0.554921481,
#            2.705050552, 0.319958247, 0.160267695,
#            3.493457419, 0.71939476,
#            0.055071723, 0.512617827, 0.016654497,
#            0.000978633, 0.000712242, 0.002950517,
#            0.0040797, 0.003156531, 0.003005276]
# }
#
# df = pd.DataFrame(data)
#
# # 计算每组的均值与标准误
# summary = df.groupby('Group')['RQ'].agg(['mean', 'sem']).reset_index()
#
# # 绘制图形
# plt.figure(figsize=(8,6))
# colors = ['#A0C4FF']*3 + ['#FFADAD']*3  # NC蓝色，AR粉色
# bars = plt.bar(summary['Group'], summary['mean'], yerr=summary['sem'],
#                capsize=5, color=colors, edgecolor='black')
#
# # 坐标轴和标题
# plt.ylabel('METTL1 Gene Expression(RQ)', fontsize=12)
# plt.xlabel('Group', fontsize=12)
# plt.title('METTL1 Expression Levels in NC and AR Groups', fontsize=14)
#
# # 美化显示
# plt.xticks(rotation=0)
# plt.tight_layout()
# plt.savefig('E:/桌面/小欣/免疫组化/2.png', dpi=300, bbox_inches='tight')
# plt.show()
# import pandas as pd
# import matplotlib.pyplot as plt
# import numpy as np
# import seaborn as sns
#
# # Data (outlier 66.41584456 removed)
# groups = (
#     ['NC:1']*3 + ['NC:2']*3 + ['NC:3']*2 +   # NC:3 now has 2 samples
#     ['AR:1']*3 + ['AR:2']*3 + ['AR:3']*3
# )
# rq_values = [
#     0.385113488, 0.202102007, 0.554921481,   # NC:1
#     2.705050552, 0.319958247, 0.160267695,   # NC:2
#     3.493457419, 0.71939476,                 # NC:3 (removed 66.41584456)
#     0.055071723, 0.512617827, 0.016654497,   # AR:1
#     0.000978633, 0.000712242, 0.002590517,   # AR:2
#     0.00404977, 0.003156531, 0.003050276     # AR:3
# ]
#
# df = pd.DataFrame({'Group': groups, 'RQ': rq_values})
#
# # Compute mean and SEM
# summary = df.groupby('Group')['RQ'].agg(['mean', 'sem']).reindex(
#     ['NC:1','NC:2','NC:3','AR:1','AR:2','AR:3']
# ).reset_index()
#
# # Plot settings
# sns.set(style="whitegrid")
# fig, ax = plt.subplots(figsize=(8,6))
#
# # Barplot with error bars (SEM)
# palette = ['#A0C4FF']*3 + ['#FFADAD']*3
# bars = ax.bar(summary['Group'], summary['mean'], yerr=summary['sem'],
#               capsize=6, color=palette, edgecolor='black', linewidth=0.8)
#
# # Overlay scatter points with jitter
# for i, grp in enumerate(summary['Group']):
#     y = df[df['Group'] == grp]['RQ'].values
#     x_jitter = np.random.normal(i, 0.06, size=len(y))
#     ax.scatter(x_jitter, y, color='black', s=30, zorder=5)
#
# # Axis labels and formatting
# ax.set_ylabel('METTL1 Expression (RQ)', fontsize=12)
# ax.set_xlabel('')
# ax.set_title('METTL1 Expression by Group', fontsize=14)
# ax.set_xticks(np.arange(len(summary['Group'])))
# ax.set_xticklabels(summary['Group'], fontsize=11)
# ax.tick_params(axis='y', labelsize=11)
# sns.despine(ax=ax, offset=5, trim=True)
# plt.tight_layout()
#
# # Save high-resolution figure
# plt.savefig('E:/桌面/小欣/免疫组化/2.png', dpi=300, bbox_inches='tight')
# plt.show()
# height = 1.75
# weight = 80.5
# bmi =weight/(height*height)
# if bmi < 18.5:
#     print('Underweight')
# elif bmi < 25:
#     print('Normal')
# elif bmi < 28:
#     print('Overweight')
# elif bmi < 32:
#     print('fat')
# else:
#     print('Overfat')
# score=123
# match score:
#     case x if x>100:
#         print("x is greater than 100")
#     case "b":
#         print("B")
#     case "c":
#         print("C")
#     case _:
#         print("no")
# names = ['Bart', 'Lisa', 'Adam']
# for name in names:
#     print(f"Hallo,{name}")


# 两地气候对比图
# import rasterio
# import numpy as np
# import matplotlib.pyplot as plt
# import os
#
# # ----------------------------
# # Parameters
# # ----------------------------
# base_dir = r"E:\桌面\武汉数据\乌珠穆沁白牛\白牛文章\气候数据"
# tmin_dir = os.path.join(base_dir, "tmin")
# tmax_dir = os.path.join(base_dir, "tmax")
# prec_dir = os.path.join(base_dir, "prec")
#
# coords = {
#     "West Ujimqin": (116.98, 44.10),
#     "Paris": (2.35, 48.85)
# }
#
# year = 2024
# months = np.arange(1, 13)
#
# # ----------------------------
# # Function to extract monthly data
# # ----------------------------
# def extract_monthly_data(folder, year, coords):
#     monthly_values = {name: [] for name in coords.keys()}
#     for month in months:
#         month_str = f"{month:02d}"
#         file_path = os.path.join(folder, f"wc2.1_cruts4.09_10m_{os.path.basename(folder)}_{year}-{month_str}.tif")
#         if not os.path.exists(file_path):
#             raise FileNotFoundError(f"File not found: {file_path}")
#         with rasterio.open(file_path) as src:
#             for name, (lon, lat) in coords.items():
#                 row, col = src.index(lon, lat)
#                 val = src.read(1)[row, col]
#                 monthly_values[name].append(val)
#     return monthly_values
#
# # ----------------------------
# # Read data
# # ----------------------------
# tmin_data = extract_monthly_data(tmin_dir, year, coords)
# tmax_data = extract_monthly_data(tmax_dir, year, coords)
# prec_data = extract_monthly_data(prec_dir, year, coords)
#
# # ----------------------------
# # Define colors
# # ----------------------------
# line_colors = {
#     "West Ujimqin": {"Tmax": "#D38C5E", "Tmin": "#F6DBA8"},
#     "Paris": {"Tmax": "#009846", "Tmin": "#C6DA88"}
# }
#
# prec_colors = {
#     "West Ujimqin": "#D38C5E",
#     "Paris": "#009846"
# }
#
# # ----------------------------
# # Set global font
# # ----------------------------
# plt.rcParams["font.family"] = "Times New Roman"
# plt.rcParams["font.size"] = 14
# plt.rcParams["axes.titlesize"] = 16
# plt.rcParams["axes.labelsize"] = 14
# plt.rcParams["xtick.labelsize"] = 12
# plt.rcParams["ytick.labelsize"] = 12
# plt.rcParams["legend.fontsize"] = 12
#
# # ----------------------------
# # Figure 1: Monthly Tmin/Tmax Comparison
# # ----------------------------
# plt.figure(figsize=(8,5))
# for name in coords.keys():
#     plt.plot(months, tmin_data[name], marker='o', linestyle='--',
#              label=f"{name} Tmin", color=line_colors[name]["Tmin"], linewidth=2.5)
#     plt.plot(months, tmax_data[name], marker='o', linestyle='-',
#              label=f"{name} Tmax", color=line_colors[name]["Tmax"], linewidth=2.5)
#
# plt.xticks([1,6,12])
# plt.xlabel("Month")
# plt.ylabel("Temperature (°C)")
# plt.title(f"{year} Monthly Tmin/Tmax Comparison")
# plt.legend()
# plt.grid(False)
# plt.tight_layout()
# plt.savefig(os.path.join(base_dir, f"Temperature_Comparison_{year}.png"), dpi=600)
# plt.close()
#
# # ----------------------------
# # Figure 2: Monthly Precipitation Comparison
# # ----------------------------
# plt.figure(figsize=(8,5))
# bar_width = 0.4  # 每组两柱并排
# plt.bar(months - bar_width/2, [prec_data["West Ujimqin"][i] for i in range(12)],
#         width=bar_width, label="West Ujimqin", color=prec_colors["West Ujimqin"])
# plt.bar(months + bar_width/2, [prec_data["Paris"][i] for i in range(12)],
#         width=bar_width, label="Paris", color=prec_colors["Paris"])
#
# plt.xticks([1,6,12])
# plt.xlabel("Month")
# plt.ylabel("Precipitation (mm)")
# plt.title(f"{year} Monthly Precipitation Comparison")
# plt.legend()
# plt.grid(False)
# plt.tight_layout()
# plt.savefig(os.path.join(base_dir, f"Precipitation_Comparison_{year}.png"), dpi=600)
# plt.close()
#
# print("Plots completed. PNG files saved in the data directory.")
#
# # ----------------------------
# # Print extracted data
# # ----------------------------
# print(f"\n=== {year} Monthly Tmin/Tmax (°C) ===")
# print("{:<6} {:<15} {:<12} {:<12} {:<12}".format("Month", "West Ujimqin Tmin", "West Ujimqin Tmax", "Paris Tmin", "Paris Tmax"))
# for i in range(12):
#     print("{:<6} {:<15.1f} {:<12.1f} {:<12.1f} {:<12.1f}".format(
#         i+1, tmin_data["West Ujimqin"][i], tmax_data["West Ujimqin"][i],
#         tmin_data["Paris"][i], tmax_data["Paris"][i]
#     ))
#
# print(f"\n=== {year} Monthly Precipitation (mm) ===")
# print("{:<6} {:<15} {:<12}".format("Month", "West Ujimqin Precip", "Paris Precip"))
# for i in range(12):
#     print("{:<6} {:<15.1f} {:<12.1f}".format(
#         i+1, prec_data["West Ujimqin"][i], prec_data["Paris"][i]
#     ))
# import matplotlib.pyplot as plt
# import os
#
# # 保存路径
# save_dir = r"E:\桌面\武汉数据\乌珠穆沁白牛\白牛文章"
# os.makedirs(save_dir, exist_ok=True)  # 如果目录不存在则创建
# save_path = os.path.join(save_dir, "cross_star_compass_N.png")
#
# # 创建画布
# fig, ax = plt.subplots(figsize=(2, 2))
# ax.set_xlim(-1, 1)
# ax.set_ylim(-1, 1)
# ax.axis('off')
#
# # 箭头参数
# arrow_kwargs = dict(width=0.03, head_width=0.15, head_length=0.2, fc='black', ec='black', length_includes_head=True)
#
# # 绘制十字箭头（上、下、左、右）
# ax.arrow(0, 0, 0, 0.5, **arrow_kwargs)   # 上
# ax.arrow(0, 0, 0, -0.5, **arrow_kwargs)  # 下
# ax.arrow(0, 0, 0.5, 0, **arrow_kwargs)   # 右
# ax.arrow(0, 0, -0.5, 0, **arrow_kwargs)  # 左
#
# # 添加北方标识 N（上移，距离箭头顶部约0.1-0.15单位）
# ax.text(0, 0.7, 'N', ha='center', va='center', fontsize=20, fontweight='bold')
#
# # 保存为透明背景PNG
# plt.savefig(save_path, dpi=600, transparent=True, bbox_inches='tight', pad_inches=0.05)
# plt.close(fig)
#
# print(f"指南针已保存到: {save_path}")
# def scs(x1,x2):
#     if {i for i in x1}=={i for i in x2}:
#         print(f"{x1},{x2}是变位词")
# #测试
# word1="heart"
# word2="earth"
# scs(word1,word2)
# def scs(x1, x2):
#     if len(x1) != len(x2):
#         print("Not equal")
#         return
#
#     x1 = list(x1)
#     x2 = list(x2)
#
#     for ch in x1:
#         for i, y in enumerate(x2):
#             if ch == y:
#                 x2[i] = None
#                 break
#         else:
#             # 注意：这个 else 是跟 for 配的，不是跟 if 配的！
#             # 只有当内层 for 没有遇到 break（也就是完全没匹配上）时才会执行
#             print("Not equal")
#             return
#
#     print("equal")
#
# word1="heart"
# word2="earth"
# scs(word1,word2)
# def add_end(L=[]):
#     L.append('END')
#     return L
# add_end([1,2,3])
# add_end([1,2,3])
# print(add_end([1,2,3]))

# def mul(x,*args):
#
#     sum=x
#     for i in args:
#         sum=sum*i
#     return sum
# print(mul(5,2))

# 我们要拟合的目标：希望 a * x ≈ y_true
# 我们先造一点“假数据”：每个样本有3个特征，对应一个y
# 真实关系：y = 2*x1 + 0.5*x2 - 1*x3 + 1 （我们故意设的真值）
# X = [
#     [ 1.0,  2.0,  3.0],
#     [ 0.5, -1.0,  2.0],
#     [ 2.0,  0.0,  1.0],
#     [-1.0,  1.0, -0.5],
# ]
#
# def true_fn(x):
#     return 2.0*x[0] + 0.5*x[1] - 1.0*x[2] + 1.0
#
# Y = [true_fn(x) for x in X]
#
#
# class LinearModel:
#     def __init__(self, n_features):
#         # 权重向量 w1, w2, w3, ...
#         self.w = [0.0] * n_features
#         # 偏置 b
#         self.b = 0.0
#
#     def predict_one(self, x):
#         """
#         对单个样本 x 预测： y_hat = w·x + b
#         x 是一个列表，例如 [x1, x2, x3]
#         """
#         y = self.b
#         for wi, xi in zip(self.w, x):
#             y += wi * xi
#         return y
#
#     def predict(self, X):
#         """
#         对一批样本预测
#         X 是样本列表，每个元素都是一个特征列表
#         """
#         return [self.predict_one(x) for x in X]
#
#     def loss(self, X, Y):
#         """
#         计算均方误差损失（MSE）
#         """
#         preds = self.predict(X)
#         total = 0.0
#         for y_hat, y_true in zip(preds, Y):
#             total += (y_hat - y_true) ** 2
#         return total / len(X)
#
#     def fit(self, X, Y, lr=0.1, epochs=50):
#         """
#         用最简单的“全量梯度下降”训练模型参数 self.w, self.b
#         """
#         n = len(X)  # 样本数
#
#         for epoch in range(epochs):
#             # 1. 先算当前的预测和损失
#             preds = self.predict(X)
#
#             # 2. 计算对每个参数的梯度（解析式，已经推好公式）
#             # 初始化梯度为0
#             grad_w = [0.0] * len(self.w)
#             grad_b = 0.0
#
#             for x, y_hat, y_true in zip(X, preds, Y):
#                 error = y_hat - y_true  # 预测 - 真实
#
#                 # 对每个 w_j 累加梯度
#                 for j in range(len(self.w)):
#                     grad_w[j] += error * x[j] / n
#
#                 # 对 b 的梯度
#                 grad_b += error / n
#
#             # 3. 按梯度下降规则更新参数
#             for j in range(len(self.w)):
#                 self.w[j] -= lr * grad_w[j]
#             self.b -= lr * grad_b
#
#             # 每隔几轮打印一下看看
#             if epoch % 5 == 0 or epoch == epochs - 1:
#                 current_loss = self.loss(X, Y)
#                 print(f"epoch {epoch:2d}: loss={current_loss:.6f}, w={self.w}, b={self.b:.4f}")
#
#
# # ======= 运行训练 =======
# model = LinearModel(n_features=3)
#
# print("初始参数：", model.w, model.b, "初始loss:", model.loss(X, Y))
# model.fit(X, Y, lr=0.1, epochs=50)
# print("训练结束后的参数：", model.w, model.b)
# print("真实参数应该接近: w=[2.0, 0.5, -1.0], b=1.0")
# def move(n, a, b, c):
#     if n == 1:
#         print(a, '-->', c)
#     else:
#         move(n-1, a, c, b)
#         print(a, '-->', c)
#         move(n-1, b, a, c)

# def trim(s):
#     while s and s[0]==' ':
#         s=s[1:]
#     while s and s[-1]==' ':
#         s=s[:-1]
#     return s
#
# if trim('hello  ') != 'hello':
#     print('测试失败!')
# elif trim('  hello') != 'hello':
#     print('测试失败!')
# elif trim('  hello  ') != 'hello':
#     print('测试失败!')
# elif trim('  hello  world  ') != 'hello  world':
#     print('测试失败!')
# elif trim('') != '':
#     print('测试失败!')
# elif trim('    ') != '':
#     print('测试失败!')
# else:
#     print('测试成功!')
#
# def findMinAndMax(L):
#
#     if not L:
#         return (None, None)
#     L_min = L[0]
#     L_max = L[0]
#     for x in L:
#         if x < L_min:
#             L_min = x
#         if x > L_max:
#             L_max = x
#     return (L_min, L_max)
#
# if findMinAndMax([]) != (None, None):
#     print('测试失败!')
# elif findMinAndMax([7]) != (7, 7):
#     print('测试失败!')
# elif findMinAndMax([7, 1]) != (1, 7):
#     print('测试失败!')
# elif findMinAndMax([7, 1, 3, 9, 5]) != (1, 9):
#     print('测试失败!')
# else:
#     print('测试成功!')
# def trim(s):
#     while s[0]==' ' and s!='' :
#         s=s[1:]
#     while s and s[-1]==' ':
#         s=s[:-1]
#     return s
#
# # 测试:
# if trim('hello  ') != 'hello':
#     print('测试失败!')
# elif trim('  hello') != 'hello':
#     print('测试失败!')
# elif trim('  hello  ') != 'hello':
#     print('测试失败!')
# elif trim('  hello  world  ') != 'hello  world':
#     print('测试失败!')
# elif trim('') != '':
#     print('测试失败!')
# elif trim('    ') != '':
#     print('测试失败!')
# else:
#     print('测试成功!')
# def findMinAndMax(L):
#     if not L:
#         return (None, None)
#     L_min=L[0]
#     L_max=L[0]
#     for i in L:
#         if i<L_min:
#             L_min=i
#         if i>L_max:
#             L_max=i
#     return (L_min, L_max)
#
# if findMinAndMax([]) != (None, None):
#     print('测试失败!')
# elif findMinAndMax([7]) != (7, 7):
#     print('测试失败!')
# elif findMinAndMax([7, 1]) != (1, 7):
#     print('测试失败!')
# elif findMinAndMax([7, 1, 3, 9, 5]) != (1, 9):
#     print('测试失败!')
# else:
#     print('测试成功!')
def triangles():
    L=[1]
    while True:
        yield L
        L=[1]+[L[i-1]+L[i]for i in range(1,len(L))]+[1]
n = 0
results = []
for t in triangles():
    results.append(t)
    n = n + 1
    if n == 10:
        break

for t in results:
    print(t)

if results == [
    [1],
    [1, 1],
    [1, 2, 1],
    [1, 3, 3, 1],
    [1, 4, 6, 4, 1],
    [1, 5, 10, 10, 5, 1],
    [1, 6, 15, 20, 15, 6, 1],
    [1, 7, 21, 35, 35, 21, 7, 1],
    [1, 8, 28, 56, 70, 56, 28, 8, 1],
    [1, 9, 36, 84, 126, 126, 84, 36, 9, 1]
]:
    print('测试通过!')
else:
    print('测试失败!')