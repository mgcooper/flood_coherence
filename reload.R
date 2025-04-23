# reload.R

# Function to source all .R files in a directory
reload <- function(function_path = "./R") {
   setwd(function_path)
   file_list <- list.files(pattern = "\\.R$", full.names = TRUE)
   for (file in file_list) {
      source(file)  # Source each file
   }
   setwd("..")  # Return to the previous directory
}
