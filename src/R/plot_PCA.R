library(ggplot2)
library(RColorBrewer)

args<-commandArgs()

input_file_name <- args[6]
output_file_name <- args[7]

colours = colorRampPalette(brewer.pal(9,"Set1"))(9)

x <- read.table(input_file_name)
x$Population <- x$V1

pdf(file=output_file_name)  
for (i in 3:10) {
	x_axis=paste("V", i, sep = "")
	y_axis=paste("V", i+1, sep = "")
	p <- ggplot(x, aes_string(x=x_axis, y=y_axis)) +geom_point(aes(color=Population), size = 2) + xlab(paste("PCA", i-2)) + ylab(paste("PCA", i-1)) + scale_colour_manual(values = colours)
	print(p)
}
dev.off()
