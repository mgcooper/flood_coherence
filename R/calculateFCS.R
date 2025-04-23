#' Calculate Flood Coherence Scores (FCS)
#'
#' This function calculates the Flood Coherence Scores (FCS) for each flood event in a specified group (groupA) by counting how many members of another group (groupB) experience simultaneous flooding events within a defined time window.
#'
#' @param floodsDataFrame A data frame containing flood event data.
#' @param peakDateColumn The name of the column in `floodsDataFrame` that contains the flood peak dates.
#' @param windowDays The size of the time window in days within which floods are considered simultaneous.
#' @param groupA A vector of names identifying the main group of interest within `floodsDataFrame` whose flood events are analyzed.
#' @param groupB A vector of names identifying the comparison group within `floodsDataFrame` whose flood events are checked for simultaneity against each event in `groupA`.
#' @return A data frame with flood coherence scores for each event in `groupA`, including a column for each member of `groupB` indicating the count of simultaneous flood events.
#' @export
#' @examples
#' # Assuming 'df' is a data frame with columns 'Peak_date', 'BasinName', and others.
#' df <- data.frame(
#'   Peak_date = as.Date(c("2021-01-01", "2021-01-02")),
#'   BasinName = c("Basin1", "Basin2"),
#'   FloodIntensity = c(100, 200)
#' )
#' calculateFCS(df, "Peak_date", 3, "BasinName", c("Basin1", "Basin2"))
calculateFCS <- function(floodsDataFrame,
                         peakDateColumn = "Peak_date",
                         windowDays = 3,
                         groupA = names(floodsDataFrame),
                         groupB = names(floodsDataFrame)) {

   # Validate the presence of the specified groups within the data
   if (!all(groupA %in% names(floodsDataFrame))) {
      stop("Some basins specified in groupA are not present in the data.")
   }
   if (!all(groupB %in% names(floodsDataFrame))) {
      stop("Some basins specified in groupB are not present in the data.")
   }

   # Initialize a list to store results
   FCSresults <- list()

   # Compute FCS for each subbasin in groupA as a reference
   for (memberA in groupA) {
      PeaksA <- floodsDataFrame[[memberA]][[peakDateColumn]]
      results <- data.frame(PeakDate = PeaksA, stringsAsFactors = FALSE)

      # Compute coherence between A and all members of groupB
      for (memberB in groupB) {
         if (memberB != memberA) {
            PeaksB <- floodsDataFrame[[memberB]][[peakDateColumn]]

            # Compute the coherence matrix
            floodCoherence <- sapply(PeaksA, function(A) {
               sum(abs(A - PeaksB) <= days(windowDays))
            })

            # Add the coherence results to the data frame
            results[[paste(memberB, "Coherence", sep = "_")]] <- floodCoherence
            results[[paste(memberB, "IsCoherent", sep = "_")]] <- floodCoherence > 0
         }
      }

      # Calculate the FCS for each event in this basin
      results$FCS <- rowSums(results[, grep("_Coherence", names(results))])

      # Store the results for this basin
      FCSresults[[memberA]] <- results
   }

   return(FCSresults)
}
