---
title: "Homework: Iteration for reading and processing spatial data"
author: "Matt Ring"
date: "10/6/2021"
output: html_document
---

<!-- Please knit this right away! The additional information for (html and css)
are provided to help you build on your current R Markdown toolbox. You will not
be responsible for learning these additional tools at this point. -->

<!-- The head tag, <head>, is a container for metadata in an html document. 
We can use it to define styles and do lots of other cool things things. -->
<head>
<!-- The link tag, <link>, creates a relationship between this file and
an external source. Here, I'm linking font-awesome so I can include a 
couple of icons that I like (user-secret and user-circle) -->
<link 
  rel="stylesheet" 
  href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<!-- Here I'm linking to a javascript file that will give us access to font awesome -->
  <script src="https://kit.fontawesome.com/03064bdd6c.js" crossorigin="anonymous"></script>
</head>
<!-- Note in the above that some html tags, like <head> need to be closed 
with </head>. Others, like <link> don't need a closing tag. -->



<!-- Here is the setup -->



<hr>

## Overview

In this exercise, you will be reading and processing spatial and implicitly spatial data files using iteration. We will be working with derived spatial data files from the US Census (tigris) and Covid-19 data from the New York Times GitHub repository for covid data (<a href = 'https://github.com/nytimes/covid-19-data' target = "_blank">link</a>).

You will be generating two files as you complete this homework -- this R markdown file, which you will be editing and adding to, and your own script file. You will submit both files.

<!-- A div is a container for html. I assign it to the class "my secret that
we created above -->
<div class = "mysecret">
<!-- The i tag is commonly used to create italic text, but it can also be 
used to create icons -->
<i class="fas fa-user-secret"></i> When I create an R Markdown file to communicate a coding process, I usually work in a .R script file and copy-and-paste the code into the R Markdown document at the end.
</div>

<hr>

<span style = "color: red; font-size: 36px"><i class="fas fa-exclamation-triangle"></i> **Important**</span> 

<hr>

## Getting started

If you haven't already, please start by knitting this file.

The data for this assignment is placed in a compressed folder on Canvas called "homework_iteration.zip". Download the file to your data/raw folder.

Open R Studio. Please ensure that the Global Options for R Markdown are set to "Show output preview in Viewer Pane". This will allow you to view the knitted document (i.e., the html version of this file) right next to your code.

Please ensure that you are starting with a clean session. Do the following before continuing:

1. If there are any script files open in your source pane, close them. If any of the file titles are blue, save them prior to closing.

2. In the *Environment* tab of your **workspace pane**, ensure that your **global environment** is empty. If it is not, click the *broom* to remove all objects.

3. In the *History* tab of your **workspace pane**, ensure that your history is empty. If it is not, click the *broom* to remove your history.

Create a script file:

1. Open a new script file.

2. Save the file right away. Please save it as the following, but **replace my name with yours**: `scripts/homework_iteration_Brian_Evans.R`.

3. Add a new code section (Ctrl or Cmd R) and call it "setup"

4. Add a space after your section break and include and run the following:



5. Add a space after the above and unzip the homework folder using by typing and running the following:


```r
unzip(
  zipfile =  'data/raw/homework_iteration.zip',
  exdir = 'data/raw')
```

*Note: The `zipfile =` argument specifies the read path. The `exdir =` argument specifies the write path. In the above, a new folder is generated for our current homework. We will remove this folder at the end of our session.*

<hr>

## Background

### Reading in files

If we want to read in a single file, we provide the path to the file inside (optimally) the `read_csv()` function:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

We can modify the statement above, by using the base R function `file.path()` to construct our file path:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

If we have to read in multiple files, this repetition can lead to errors and unnecessarily long code. We can avoid this by assigning a read directory to our global environment (*Note: Only relative paths are required because we're working in a project*):


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

But this still leads to redundant code if we have to read in a lot of files:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

### Reading in multiple files with iteration

Reading in a lot of files at once can lead to undue repetition in our scripts.

Let's use the `list.files()` function to see the files in our homework directory:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

That's a lot of files! We can subset to just the files of interest by specifying a pattern we want to search for, using the argument `pattern = `. Let's search for *.csv* files:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

If we want to also return the path to the files, we can add `full.names = TRUE` to our argument:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

*Note in the above, I separated the code block into multiple lines because there are more than two arguments supplied to `list.files()`*.

We can use the above, in combination with `purrr::map()` to read in all of our files at once. Let's assign it as a list file to our global environment:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

If you ran and explored the above, you probably noticed we didn't assign any names to our objects -- they are only defined by index (position). 


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

We can specify the names to our object using the `set_names()` function. I like to assign my names to the global environment to avoid reduncancy in the code:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

So, now we have names, but they're terrible ones. Things get a little better if we use the `file.path()` function inside our `map()`:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

Our names are still terrible. They've got *.csv* in them -- because the files are not comma separated values (each is a tibble object), this name isn't appropriate. We can use the function `str_remove()` function from the `stringr` package in `tidyverse` to remedy this when we set the names:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

Of course, we may not want a list object -- we probably just want to put our objects inside of the global environment itself. To do so, we use the function `list2env()` and specify the environment as `.GlobalEnv`. This is how our full iterative data-reading code block is written:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

<div class = "now_you">

<i class="fas fa-user-circle"></i> 

1. <span class = "score">[0.5 points]</span>  Use `st_read()` to read in the file `conus_counties.shp` from the folder "data/raw/homework_iteration", using the `file.path()` function to specify the location of the file:



2. <span class = "score">[0.5 points]</span>  Generate a vector of character values, where each value represents the names of the shapefiles (`*.shp`) in `read_dir`. Assign the character vector to your global environment with the name `shp_names`:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

3. <span class = "score">[1.0 points]</span> Using the vector `shp_names`, read in all of the shapefiles in `read_dir` at once and assign them to your global environment (without an extension in the assigned name).
    

```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

</div>

### Reading and processing files

The real power of reading files with iteration (especially with spatial files) comes with including data processing in the iteration.

For example, I really dislike upper-case letters in my column names. Let's look at the column names of `mask_use`:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

I can set all of the names to lowercase using the function `tolower()`:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

We can also do this to all of our files at once, as we read them in (*Note: Only `mask_use.csv` really has uppercase names, this is just an example*):


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

<hr>

<div class = "now_you">

<i class="fas fa-user-circle"></i> 

4. <span class = "score">[0.5 points]</span> ESRI shapefiles typically have field names (i.e. column names) in all uppercase letters. This is annoying, but easily dealt with by processing a file as we read it in. In a single piped statement, read in the file `conus_counties.shp` and change the names of the fields to lowercase.


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

5. <span class = "score">[1.0 points]</span> Modify your code from question 3 such that it converts all of the field names to lowercase before assigning each object to your global environment.


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

6. <span class = "score">[1.0 points]</span> While reading in a file, we may want to convert the coordinate reference system (CRS). Read in `conus_counties.shp` and transform the CRS to EPSG 5070 (NAD83 with a Conus Albers projection):


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

7. <span class = "score">[1.0 points]</span> Rather than transforming each file one-by-one, we can convert them all while reading in the files. Modify your code from Question 5 such that it reads in the files, makes all of the field names of each file lowercase, **and** transforms the CRS to EPSG 5070:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

</div>

<hr>

### Iteration with control flow constructs 

A **control flow construct** defines when an execution occurs. With *for loops* and `purrr::map()` (behind the scenes), we used control flow constructs to define an iteration.

For example, let's look at the following *for loop* statement:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

Above, when we used the control flow construct `for(i in 1:length(x))`, we specified that we want to execute a function (`x[i] + 1`) on each of the indices (i.e., positions) in vector `x`. Each function was run separately for each index of `x`. 

Another control flow construct that we commonly use in R is the `if(logical test) {} else {}` statement. We can use this control flow construct to do one thing if a logical test evaluates to TRUE or something else if it evaluates to FALSE:


```r
if(a == b) {
  do this
} else {
  do that
}
```


Let's see how it works inside of a *for loop*:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

We could have also done this inside of a `map()` function (*Note: Here I'm using `map_dbl()`, which returns a vector of numbers instead of a list*):


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

### Using a control flow construct with a data frame

Let's see how we'd use this with a data frame. We can test whether the word state is in a given data frame as such:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

*Note: The curly brackets above generate an environment that isolates the logical test. Without this, the pipe would try to pass the data to the word "state", which will generate an error.*

The `prison_systems` data frame contains the column `state` whereas `mask_use` does not. We can use our `if(logical test) {} else {}`construct to subset the column if it exists, or return the full data frame if it does not.

Let's subset to "California", but only if there is a `state` column:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

*Note that we have to provide an environment for our logical test above by wrapping the entire `if(logical test) {} else {}` statement inside curly brackets.*

We can do the above with iteration by placing this inside of a `map()` function while reading in the data:


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

The above is very useful for reading in shapefiles, because it can be used to reduce the size of a file before more memory-intensive processing steps like `st_transform()`.

<div class = "mysecret">
<i class="fas fa-user-secret"></i> When working with geospatial objects **always** make sure that the size of the object is no larger than is needed! Otherwise, out-of-memory errors are lurking in your not-to-distant future.
</div>

<div class = "now_you">
<i class="fas fa-user-circle"></i> 

8. <span class = "score">[1.5 points]</span> In a single piped statement (i.e., without assigning any new object to your global environment):

    a. Read in the file `conus_counties.shp`
    b. Set the field names to lowercase
    c. Subset the file to the state of California
    d. Transform the CRS to EPSG 5070
    e. Make a map of the file using ggplot() with each county filled using the field of your choosing (e.g., `aes(fill = name)`).
    

```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```
    
9. <span class = "score">[1.5 points]</span> Below, I provide a vector of states that are classified as the Western United States. In a single piped statement:

    a. Read in all of the shapefiles
    b. Set the field names to lowercase
    c. Subset the file to the `western_states` states (*Hint: Use a control flow construct!*)
    d. Transform the CRS to EPSG 5070
    e. Assign the object to your global environment as a list object with the name `western_shapes`. Individual list items should include their original file name, but without the extension `*.shp`.
    

```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

10. <span class = "score">[1.5 points]</span> In a single piped statement that uses the `western_shapes$conus_states` and the `prison_systems` table:

    a. Join the data from the `prison_systems` to `western_shapes$conus_states`, maintaining only matching rows
    b. Subset the data to the fields: `state`, `total_inmate_cases`, and `max_inmate_population_2020`
    c. Calculate the percentage of inmates in each state that tested positive for Covid-19.
    d. Generate a map in which the fill color for each state is dependent on the percentage of positive cases in each state.
    


```
## knitr
```

```
## knitr
```

```
## tidyverse
```

```
## sf
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

```
## purrr
```

</div>

## Ending your session and submission

1. Remove all of the objects assigned to your global environment using either `rm(ls())` or clicking the broom icon in the Environment tab. This will ensure that your knitted document is only dependent on objects that are generated or modified by the code in your R Markdown file.

1. Knit the output. You may receive an error in doing so. If that occurs, it is most likely associated with the code in one of your code chunks. By default, knitting a document will fail if you have an error in your code. Use the error message to try to see where the error occurred (*Note: the line number provided in an error message represents the line number at the top of a given code chunk, not the specific location of the error*). 

1. Attempt to fix any errors that caused knitting failures (if any existed).

1. If you are unable to fix a code error, add a comma at the end of the chunk options for the offending block and type `error = TRUE`.

1. Remove the folder `homework_iteration` from your `data/raw` folder using:


```r
# Clear any hidden connections

gc()

# Remove the unzipped homework folder

unlink(
  'data/raw/homework_iteration',
  recursive = TRUE)
```

6. Save this document and your R script file in your project folder and submit both files to Canvas.



<hr>

