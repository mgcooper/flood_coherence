calculateFCS2 <- function(floodsDataFrame,
                          peakDateColumn = "Peak_date",
                          windowDays = 3,
                          groupA = names(floodsDataFrame),
                          groupB = names(floodsDataFrame)) {

   # Validate the presence of specified groups within the data
   if (!all(groupA %in% names(floodsDataFrame))) {
      stop("Some basins specified in groupA are not present in the data.")
   }
   if (!all(groupB %in% names(floodsDataFrame))) {
      stop("Some basins specified in groupB are not present in the data.")
   }

   # Initialize results storage
   FCSresults <- list()

   # Compute FCS for each subbasin in groupA as a reference
   for (memberA in groupA) {
      PeaksA <- floodsDataFrame[[memberA]][[peakDateColumn]]
      results <- data.frame(PeakDate = PeaksA, stringsAsFactors = FALSE)

      # Initialize a matrix to store coherence results for this member of Group A
      coherenceMatrix <- matrix(nrow = length(PeaksA), ncol = length(groupB), dimnames = list(NULL, groupB))

      # Compute coherence for each member in Group B
      for (i in seq_along(groupB)) {
         memberB <- groupB[i]
         if (memberB != memberA) {
            PeaksB <- floodsDataFrame[[memberB]][[peakDateColumn]]
            # Calculate coherence vector for this pair (memberA, memberB)
            coherenceVector <- sapply(PeaksA, function(onePeak) {
               sum(abs(onePeak - PeaksB) <= days(windowDays))
            })
            coherenceMatrix[, i] <- coherenceVector
         }
      }

      # Calculate the FCS for each event in this basin
      results$Total_FCS <- rowSums(coherenceMatrix)

      # Store the results for this basin
      FCSresults[[memberA]] <- list(Results = results, CoherenceMatrix = coherenceMatrix)
   }

   return(FCSresults)
}
