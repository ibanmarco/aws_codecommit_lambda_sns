provider "aws" {
    profile = "${var.PL_ROLE}"
    region = "${var.PL_REGION}"
}
