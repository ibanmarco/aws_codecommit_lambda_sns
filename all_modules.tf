module "codecommit_sns" {
  source              = "./module"
  PL_ENV              = "${var.PL_ENV}"
  PL_REGION           = "${var.PL_REGION}"
  PL_ACCOUNT_ID       = "${var.PL_ACCOUNT_ID}"
  TF_SNS_Topic_Name   = "${var.TF_SNS_Topic_Name}"
}
