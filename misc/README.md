# Getting Started Guide
The artifact is realized as a single VirtualBox image of three main components:  

1. yinyang, the tool which we created and extended, and in which we integrated TypeFuzz. TypeFuzz realizes generative type-aware mutation to find all reported bugs in the paper (`~/yinyang`); 
2. A SQLite database with a list of bugs (`~/data/database.db`) and
3. Coverage data (`~/data/records.zip`).

All three components are expected to be usable with minimal effort. We have created and tested our VM with [VirtualBox 6.1.22](https://download.virtualbox.org/virtualbox/6.1.22). The VM's username and password are both `typefuzz`, the working directory is `/home/typefuzz`. We recommend at least 8 GB of RAM and 16 GB of free disk space. For maximum performance, we recommend setting the number of CPU cores of the virtual machine to
at least half the number of CPU cores available in your host system (Settings -> System -> Processor). We provide approximate time estimates for all commands that take longer than 1 minute. 


## yinyang
TypeFuzz is a part of the SMT solver testing framework [yinyang](https://github.com/testsmt/yinyang). TypeFuzz is pre-installed and in the path. To make sure TypeFuzz is functioning correctly, execute the following command in an interactive shell: 

``` bash 
typefuzz "z3-4.8.10 model_validate=true;cvc4-1.8 -q --strings-exp" ~/yinyang/examples 
```
The command runs TypeFuzz with the two SMT solvers Z3 and CVC4 with the seeds from `~/yinyang/examples`. The expected output is progress information similar to the following:    

```
[2021/07/07 07:25:18 PM] Strategy: typefuzz, 2 testing targets, 4 seeds
[2021/07/07 07:25:19 PM] Performed 116 solver calls (114.5 calls/s, eff: 100.0%, 57.2 mutants/s)
[2021/07/07 07:25:21 PM] Performed 214 solver calls (70.8 calls/s, eff: 100.0%, 35.4 mutants/s)
[2021/07/07 07:25:23 PM] Performed 482 solver calls (95.9 calls/s, eff: 100.0%, 47.9 mutants/s)
[2021/07/07 07:25:25 PM] Performed 838 solver calls (119.2 calls/s, eff: 100.0%, 59.6 mutants/s)
User interrupt
3 seeds processed, 3 valid, 0 invalid 
0 bug triggers found
```

Besides SMT solver calls per second, TypeFuzz prints the percentage of effective solver queries.  A solver query is ineffective if the SMT solvers exceed a pre-defined timeout limit (by default 8 seconds) or the SMT solver rejects the test formula. TypeFuzz guarantees type-correct formulas.  In the large majority, efficiency drops are therefore caused by solver timeouts and rarely by unsupported features of the SMT solvers.    

The shortcut CTLR + C terminates a run of TypeFuzz. TypeFuzz selects seeds at random and generates 300 test formulas per seed (customizable with option `--iterations <NUM>`). TypeFuzz terminates once every seed is processed. It takes a sequence of SMT solvers CLIs separated by semicolons. This generic format ensures that TypeFuzz can be used to test various SMT solvers.

For more information on TypeFuzz's usage, use `typefuzz --help`. 

## SQLite database
We use an SQLite database, to present the bug-finding data of the paper. To view the database's content, we recommend a GUI like [DB Browser for SQLite](https://sqlitebrowser.org/). For the bug-finding claims, we use SQLite's CLI. 

``` bash 
sqlite3 ~/data/database.db
SELECT COUNT(*) FROM BUGS; 
```

If the output of this command is `70`, the database seems to function correctly.  SQLite's CLI can be exited by CTLR + D. 


## Coverage data (~5 minutes)
To reproduce the coverage claim, we need gcovr coverage reports. We provide the records in the zip archive `~/data/records.zip`. Unzip the archive with the following command:   

```bash
cd ~/data && unzip records.zip && cd ~
```

Since the coverage records are quite sizable, the command may take up to 5 minutes.  

# Step by Step Instructions 
This section contains (1) instructions on getting familiar with the artifact (2) steps to investigate the bug-finding claims of the paper (3) steps to reproduce the coverage claim and (4) details on TypeFuzz's implementation. 

## 1. Getting familiar with yinyang and the artifact

1. Read the section "Illustrative Example" from the paper (p.3 + p.4).
2. TypeFuzz is a part of [Project Yin-Yang for SMT solver testing](https://testsmt.github.io/) which has led to 1,500+ bug reports (900+ fixed) in the open-source SMT solvers [Z3](https://github.com/Z3Prover/z3) and [CVC4/5](https://github.com/cvc5/cvc5).
3. Since October 2020, we are actively developing the yinyang fuzzing framework for SMT solvers.  Besides generative type-aware mutation (TypeFuzz), yinyang realizes type-aware operator mutation (OpFuzz) and Semantic Fusion (YinYang), two complementary approaches for SMT solver testing. The yinyang framework has 100+ stars on GitHub and has been recognized for its contributions to open-source software (see [Google OSP](https://opensource.googleblog.com/2021/04/announcing-first-group-of-google-open-source-peer-bonus-winners.html)). 
4. Since the OOPSLA submission on April 16, TypeFuzz has doubled down on its bug-finding results. We have now reported 170+ bugs in Z3 and CVC4/5, among them many critical soundness bugs.
5. Investigate the reported bugs found by TypeFuzz by reading the section "Sampled Bugs" (p.13 - p.15). Get an impression of the types of bugs (soundness, invalid model, crashes) that TypeFuzz can find.

## 2. Investigate the bug-finding claims 
To investigate the bugs found by TypeFuzz, we next examine the bug database. The database can be conveniently browsed by a SQLite GUI such as [DB Browser for SQLite](https://sqlitebrowser.org/). 

The database consists of the following tables:   
* `BUGS`: main table with bug_id, solver, bug types, statuses, test case, and options for every bug found by TypeFuzz.    
* `BUGS_IN_RELEASES`: a table containing the historic solver releases were affected per bug by i.e. how longstanding each bug was.
* `SOLVER_RELEASES`: a table contains historic release dates of the SMT solvers Z3 and CVC4.

Additionally, the database contains the three views `BUG_STATUS_TABLE`, `BUG_TYPE_TABLE`, `BUG_OPTION_TABLE` for Fig. 5 (a), (b) and (c) respectively. We use these views as shortcuts for longer SQL to bring the data from vertical to horizontal format. You can examine the query that is executed to obtain the views' result set in DB Browser for SQLite.  

Based on the data in the database, we give queries to verify all main bug-finding claims in each section of the submitted paper (page, line number). For every number related to bug-finding, there is a query to reproduce it. We recommend the following top-down approach: (1) choose a relevant number in the paper (2) execute the corresponding query and (3) compare the results of the query with the number in the paper. Note, if numbers are repeated, we just list the first occurrence (page, line). 

### Claims in the abstract

Number of reported bugs (p.1, l.10): 

```sql
SELECT COUNT(*) FROM BUGS;
```

Number of confirmed bugs (p.1, l.11):

```sql
SELECT COUNT(*) FROM BUGS WHERE status == "Confirmed" or status == "Fixed";
```

Number of fixed bugs (p.1, l.11):

```sql
SELECT COUNT(*) FROM BUGS WHERE status == "Fixed";
```

>We found 9 soundness bugs in CVC4's default mode alone (p.1, l.12)

```sql
SELECT COUNT(*) FROM BUGS WHERE solver == "CVC4" and mode=="default" and type == "Soundness";
```

> A third (3/9) of CVC4's soundness bugs are more than 2-years latent. (p.1, l.13)

```sql
SELECT * FROM BUGS_IN_RELEASES WHERE bug_id == 21 or bug_id == 9 or bug_id == 5;
SELECT * FROM SOLVER_RELEASES WHERE solver == "CVC4";
SELECT type,status,issue_link FROM BUGS WHERE bug_id == 21 or bug_id == 9 or bug_id == 5;
```

The first query shows in which historic CVC4 releases the three bugs trigger. The second query shows the historic release dates of CVC4. The third query shows that the three bugs are soundness bugs and returns links CVC4/CVC5's issue tracker for inspection.          
 
### Claims in the introduction
> Fig. 1. shows an almost four-year latent soundness bug. (p.1, l.33 - 49)

```sql
SELECT * FROM BUGS_IN_RELEASES where bug_id == 9;
SELECT * FROM SOLVER_RELEASES WHERE solver == "CVC4";
SELECT test,issue_link FROM bugs where bug_id == 9;
```
The first query shows in which historic CVC4 releases the bug triggers. The second query shows the historic release dates of CVC4. The third query shows that the bug is a soundness bug and returns the corresponding link on CVC4/CVC5's issue tracker for inspection. 
         
### Claims in the illustrative example section
> Fig. 2 (d) triggers a soundness bug in Z3. (p.3, l.106 - 111)

```sql
SELECT test,type,issue_link FROM BUGS where bug_id == 27;
```

### Claims in the approach section
> Formula phi-mutant triggers a soundness bug in CVC4. (p.6, l.247 - 253) 

```sql
SELECT test,type,issue_link FROM BUGS where bug_id == 5;
```

### Claims in the empirical evaluation section 

Fig. 5 (a): Bug status table (p.11) 

```sql
SELECT * FROM BUG_STATUS_TABLE;
```

Fig. 5 (b): Bug types among the confirmed bugs (p.11)

```sql
SELECT * FROM BUG_TYPE_TABLE;
```

Fig. 5 (c): Number of options (mode) among the confirmed bugs (p.11)

```sql
SELECT * FROM BUG_OPTION_TABLE;
```

Top-3 logics among the confirmed Z3 bugs (p.11, l.521 - 522) 

```sql
SELECT logic, COUNT(*) FROM BUGS WHERE (status == "Confirmed" or status == "Fixed") and solver == "Z3" GROUP BY logic;
```

Top-3 logic among the confirmed CVC4 bugs (p.11, l.522 - 523) 

```sql
SELECT logic, COUNT(*) FROM BUGS WHERE (status == "Confirmed" or status == "Fixed") and solver == "CVC4" GROUP BY logic;
```

Fig. 6 (a): Confirmed bugs affecting historic Z3 releases (p.12)

```sql
SELECT version,COUNT(*) FROM BUGS_IN_RELEASES JOIN BUGS ON BUGS_IN_RELEASES.bug_id == BUGS.bug_id WHERE BUGS.solver == "Z3" and (BUGS.status=="Confirmed" or BUGS.status == "Fixed") GROUP BY BUGS_IN_RELEASES.version ORDER BY COUNT(*);

```

Fig. 6 (b): Confirmed bugs affecting historic CVC4 releases (p.12)

```sql
SELECT version,COUNT(*) FROM BUGS_IN_RELEASES JOIN BUGS ON BUGS_IN_RELEASES.bug_id == BUGS.bug_id WHERE BUGS.solver == "CVC4" and (BUGS.status=="Confirmed" or BUGS.status == "Fixed") GROUP BY BUGS_IN_RELEASES.version ORDER BY COUNT(*);
```

### Claims in the Sampled Bugs section

Fig. 9 (a) - (h) 

```sql
SELECT test,type,issue_link FROM BUGS where bug_id == 21;
SELECT test,type,issue_link FROM BUGS where bug_id == 15;
SELECT test,type,issue_link FROM BUGS where bug_id == 57;
SELECT test,type,issue_link FROM BUGS where bug_id == 47;
SELECT test,type,issue_link FROM BUGS where bug_id == 42;
SELECT test,type,issue_link FROM BUGS where bug_id == 31;
SELECT test,type,issue_link FROM BUGS where bug_id == 7;
SELECT test,type,issue_link FROM BUGS where bug_id == 5;
```

### Reproducing bugs in Z3 and CVC4 
We can use the following command to reproduce specific bugs from the database. 

```
reproduce_bug <bug_id>
```

The argument `<bug_id>` matches the corresponding attribute in the database. The script `reproduce_bug` first fetches the test from the database and writes the bug trigger `<bug_id>.smt2` to the current working directory. Next, it executes the solver (along with the flags) to trigger the bug. All solvers binaries for both trunk and stable releases are pre-built and in the path, the command lines can be copy-pasted.

Example reproducing the soundness bug from Fig. 1 (bug_id = 9):   

```
$ reproduce_bug 9
# Bug type: Soundness
# Oracle:   sat

$ cvc4-d278cfe -q --strings-exp bug9.smt2
unsat
```

The first two lines of the output contain the bug type and the ground truth result (Oracle). The next lines show the solver trace. To verify the tool's output, just copy the command in an interactive shell. To verify the ground truth of the formula, a stable release of the other solver, e.g. z3-4.8.10 is a good choice.           

Note, a few bugs (e.g. bug_id = 12) are flaky. For such bugs, it may make sense to execute `reproduce_bug <bug_id>` multiple times.   


### Finding selected bugs with TypeFuzz (optional) 

This section demonstrates TypeFuzz's bug-finding abilities.  TypeFuzz's mutation space is huge. Consequently, the likelihood of triggering a single bug in a short run is very low. This section shows three selected bugs that TypeFuzz can reproduce with high probability (~99%) in n=400 one-shot tries and customized configuration files. 

##### Soundness bug in Z3 #27 (max: 20 minutes) 

``` bash
for (( i = 0; i < 400; i++ )); do                                                      
    if ! typefuzz -c ~/yinyang/examples/c27.txt -i 1 -t 1 "cvc4-1.8 --strings-exp -q;z3-d0515dc" ~/yinyang/examples/seed27.smt2; then  
        break
    fi           
done 
```

The above command will execute typefuzz 400 times in a row and exit once it finds the soundness bug. If the bug is detected, an output similar to the following should appear:  

```
[2021/07/12 08:48:19 PM] Strategy: typefuzz, 2 testing targets, 1 seeds
[2021/07/12 08:48:19 PM] Detected soundness bug! /home/typefuzz/yinyang/bugs/incorrect-cvc4-18--strings-exp-seed27-yeUNS.smt2
```

The bug trigger is then stored in `/home/typefuzz/yinyang/bugs/incorrect-cvc4-18--strings-exp-seed27-yeUNS.smt2`. This bug corresponds to the process described in Fig. 2 of the paper. The two examples below are similar.  

#### Crash bug in CVC4 #42 (max: 20 minutes)

``` bash
for (( i = 0; i < 400; i++ )); do                                                      
    if ! typefuzz -c ~/yinyang/examples/c42.txt -i 1 -t 1 "cvc4-9f5fcab -q; z3-4.8.10" ~/yinyang/examples/seed42.smt2; then  
        break
    fi           
done 
```

#### Soundness bug in Z3 #31 (max: 20 minutes)
``` bash
for (( i = 0; i < 400; i++ )); do
    if ! typefuzz -c ~/yinyang/examples/c31.txt -i 1 -t 1 "cvc4-1.8 --strings-exp -q;z3-bf692a5" ~/yinyang/examples/seed31.smt2; then  
        break
    fi 
done
```

## 3. Investigate the coverage claim (~2h)
This section instructs how to verify the coverage evaluation from Fig. 7 and investigates the following claim:  

> TypeFuzz and OpFuzz are complementary in code coverage, i.e., cover different regions in Z3 and CVC4’s respective codebases. (p.13, l.600 - 602)

Since, Z3 and CVC4's respective codebases are large, producing a summary report is time-consuming. For Z3 and CVC4, the coverage record files are stored in `~/data/records/z3` and `~/data/records/CVC4` respectively. To view the list of files, execute the following command:   
```
find ~/data/records -name *.gcda.*
```
Files with `.gcda` suffix are gcov coverage records. For each approach, we compare in Fig. 7, we added another suffix to the `.gcda` files: `.benchmark`, `.opfuzz`, `.typfuzz`, and `.typopfuzz` matching the approaches `Seeds`, `OpFuzz`, `TypeFuzz`, and `TypeFuzz + OpFuzz` in Fig. 7 respectively.  The table in Fig. 7 can be generated by running the following command:

```
cd ~/data/records && ./extract_coverage.sh
```

The script `extract_coverage.sh` will extract the coverage information from the records and print a table to the terminal.  Intermediate logs are stored in `results_cvc4.log` and `results_z3.log`. It is expected that the prompt will not return for a longer time (1 - 2h). The expected output is the following:   


```
==================================================================
                          z3                      CVC4
                ------------------------ ------------------------
                lines functions branches lines functions branches
Seeds           17.2%   16.5%    10.6%   21.5%   39.7%     8.0%
OpFuzz          17.8%   16.8%    11.1%   22.3%   40.9%     8.4%
TypeFuzz        19.4%   18.7%    11.9%   22.2%   40.7%     8.3%
TypeFuzz+OpFuzz 19.7%   18.8%    12.2%   22.7%   40.9%     8.5%
==================================================================
```

To verify the coverage claim, check whether the percentages for OpFuzz and TypeFuzz are different and whether "TypeFuzz+OpFuzz" dominates OpFuzz and TypeFuzz. 

## 4. Building on the artifact
This section  gives a brief overview of TypeFuzz's implementation and describes how researchers and practitioners can customize and extend TypeFuzz and yinyang.

### Understanding TypeFuzz's implementation in yinyang
The following file tree shows the most important files of typefuzz and includes a brief description. 

```
yinyang
├── bin
│   └── typefuzz                        - main executable of typefuzz, cli interface
├── config
│   ├── Config.py                       - solver configurations, crash, duplicate, ignore lists
│   └── typefuzz_config.txt             - typefuzz configuration file 
├── src
│   ├── base                            - contains driver, argument parser, exitcodes, etc.
│   ├── core
│   │   └──  Fuzzer.py                  - implements the fuzzing loop and the bug checking oracle
│   ├── mutators
|   |   └── GenTypeAwareMutation
│   │       └── GenTypeAwareMutation.py - mutator integrating generative type-aware mutations
│   └── parsing
│       ├── Ast.py                      - classes for scripts, commands, expressions, etc.
│       ├── Parse.py                    - SMT-LIB v2.6 parser
│       ├── SMTLIBv2.g4                 - SMT-LIB v2.6 antlr4 grammar
│       └── Typechecker.py              - SMT-LIB v2.6 type checker
└── tests                               - contains unit, integration, and regression tests
```   

When TypeFuzz is called from the command line, it executes `bin/typefuzz` containing the main function. After parsing the command line and reading in the seeds, the method `Fuzzer.py:run` is called. It randomly pops an SMT-LIB file from the seed list (`Fuzzer.py:142`), then parses (`Fuzzer.py:98`) and type-checks (`Fuzzer.py:146`) the SMT-LIB file. Next, we compute the set of unique expressions (`Fuzzer.py:148`) from the seed and pass it to a newly created mutator GenTypeAwareMutation (`Fuzzer.py:149`). The mutator is then called in a for-loop realizing n consecutive mutations (`Fuzzer.py:171`). Each mutated formula is then passed to the SMT solvers under test which checks for soundness bugs, invalid model bugs, assertion violations, segfaults (`Fuzzer.py:185`) and dumps the bug triggers to the disk. For details on these checks, read the comments in the method `Fuzzer.py:test`.            

Generative type-aware mutation's mutator class is realized in `GenTypeAwareMutation.py`. It takes a type-checked SMT-LIB script and the set of its unique expressions as arguments to the constructor. Then, we parse the configuration file (`config/typefuzz_config.txt`) containing the operator signatures. The method `mutate` implements a mutation step. First, we call the method `get_all_subterms` to return a list of all expressions (`av_expr`) and another list with their types (`expr_type`). Next, we repeatedly choose a term t1 from the formula to be substituted by a term t2 (returned by `get_replacee`). If we could successfully construct such a term, then we substitute and return the mutated formula.

The `get_replacee(term)` method randomly chooses an operator from the list of candidate operators. The list of candidate operators contains all operators with a return type matching term's type and includes the identity operator `id`. Next, we pick a type-conforming expression from the set of unique expressions for every argument for the operator at hand and return the expression. The `get_replacee`method may fail, e.g., if we would have picked an operator of a conforming type but no term with conforming types to its arguments exist. To avoid this, we repeat the `get_replacee` method several times.

### Customizing and extending TypeFuzz and yinyang   
The yinyang framework has many tests to ensure the reliability of its mutators and the bug detection logic. All tests are integrated into a CI making sure that the bug-finding ability is preserved on every commit. yinyang adheres to the PEP 8 code quality standard. We briefly describe how researchers and practitioners can customize and extend the framework. For an in-depth overview of the yinyang framework, see the [documentation](https://yinyang.readthedocs.io/en/latest/).                 

#### Run TypeFuzz with other SMT Solvers
Besides Z3 and CVC4, TypeFuzz can be run with any other SMT solver such as [MathSAT](http://mathsat.fbk.eu), [Boolector](http://verify.inf.usi.ch/content/opensmt2), [Yices](http://yices.csl.sri.com/), and [SMT-Interpol](http://ultimate.informatik.uni-freiburg.de/smtinterpol/), etc. Since TypeFuzz is based on differential testing, it needs at least two solver configurations, ideally with a large overlap in the supported SMT logics. Furthermore, yinyang's type checker currently has stable support for string and arithmetic logics. Support for other logics is currently experimental but will be finalized shortly.

Solver configurations could either be specified in the command line or in the configuration file `config/Config.py` such as:  

```
solvers = [
    "yices-smt2 --incremental" 
    "z3 model_validate=true",
    "z3 model_validate=true smt.arith.solver=6",
    "cvc4 --check-models --produce-models --incremental --strings-exp -q",
]
```

To run TypeFuzz with these four solver configurations in the config file, you would need to run `typefuzz "" <benchmark-dir>`. Note, the `crash_list` in Config/config.py, which may need to be updated ensuring that crashes by the new solver(s) are caught.

#### Devise a custom mutator 

Fuzzing frameworks such as AFL and others have greatly benefited from the SE/PL community efforts to extend their mutation strategies. In the same spirit, we describe steps on how users can extend yinyang with custom mutators.                

1. Add a new mutator class to `src/mutators`, e.g., `CustomGenerator.py`. A mutator takes a parsed SMT-LIB script as its input and returns the mutated script. The mutation should usually be implemented in a separate mutate method `CustomGenerator.py::mutate()`. For example, consider, `src/mutators/GenTypeAwareMutation/GenTypeAwareMutation.py` or `src/mutators/TypeAwareOpMutation.py`.
2. Provide an executable in the `bin` directory and add parser code to `base/ArgumentParser.py`. 
3. Integrate the mutator in the fuzzing loop in `src/core/Fuzzer.py::run()`.

#### Extend the input language

Similar to many PLs, the [SMT-LIB language](https://smtlib.cs.uiowa.edu/language.shtml) is steadily augmented by new features, theories, etc. Furthermore, researchers use SMT-LIB dialects for their solver inputs (e.g. for sygus rewrite rules). To support such use cases, we have based yinyang's parser on an [ANTLR](https://www.antlr.org/) grammar that is simple to customize.

1. Extend grammar `src/parsing/SMTLIBv2.g4`.
2. Regenerate the grammar using `src/parsing/regenerate_grammar.sh`.
3. Extend parse tree visitor `src/parsing/AstVisitor.py` and AST implementation `src/parsing/Ast.py`.
4. If type checking is needed, augment the type checker in `src/parsing/Typechecker.py`.    
 

# Claims of the Paper Supported by the Artifact

The artifact provides evidence 
- for our bug findings in the SMT solvers Z3 and CVC4,  
- that the implementation of TypeFuzz is as described in the paper,    
- how TypeFuzz and the yinyang framework can be used and extended by researchers and practitioners.
