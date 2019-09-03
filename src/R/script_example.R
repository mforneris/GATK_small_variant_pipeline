## setup ##

library(yaml)
library(argparse)
library(ggplot2)
options(stringsAsFactors = FALSE)

CONF = yaml.load_file("../../config/config.yml")
PROJECTROOT = CONF$global$projectpath

make_recursive_dir = function(new_dir){
  if(!dir.exists(new_dir)){ dir.create(new_dir, recursive = TRUE) }  
}

## parse comand line arguments ##

parser <- ArgumentParser()
parser$add_argument("-k", default = 3, type="integer", help = "Number of clusters to find [default: %(default)s]")
parser$add_argument("-n", "--nstart", default = 20, type="integer", help = "How many random sets should be chosen? ('?kmeans' for more details) [default: %(default)s]")
parser$add_argument("-o", "--output", default = "plot.pdf", type = "character", help = "Name of the output file [default: %(default)s]")
parser$add_argument("--seed_number", type = "integer", help = "Set number to get reproducible results")

args = parser$parse_args()
k = args$k
n = args$n
file_name = args$output

## run analysis ##

data(iris)

if(exists("seed_number")) {set.seed(seed_number)}

irisCluster = kmeans(iris[, 3:4], centers = k, nstart = n)
iris$cluster <- as.factor(irisCluster$cluster)

p = ggplot(iris, aes(Petal.Length, Petal.Width, color = cluster)) + geom_point() + theme_bw()


# write output
make_recursive_dir("tmp/kmeans")
file_path = file.path("tmp/kmeans", file_name)
ggsave(file_path, p, device = "pdf")
print(paste0("Output plot saved to ", file_path))


