#!/bin/bash
# ---------------------------
# Màu sắc
# ---------------------------
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

# ---------------------------
# Hàm tạo chuỗi ngẫu nhiên
# ---------------------------
generate_random_string() {
  echo "$(LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c 5)-$(LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c 5)"
}
generate_random_numbers() {
  printf "%05d" "$(shuf -i 0-99999 -n 1)"
}
generate_random_number() {
  echo $((1000 + RANDOM % 9000))
}
generate_project_id() {
  echo "$(generate_random_string)"
}
generate_project_name() {
  echo "My Project $(generate_random_numbers)"
}
generate_valid_instance_name() {
  echo "instance-$(generate_random_number)"
}
rand_sleep() {
  sleep $((1 + RANDOM % 3))
}

# ---------------------------
# Lấy thông tin tổ chức + billing
# ---------------------------
organization_id=$(gcloud organizations list --format="value(ID)" 2>/dev/null)
echo -e "${YELLOW}ID tổ chức của bạn là: $organization_id ${NC}"
billing_account_id=$(gcloud beta billing accounts list --format="value(name)" | head -n 1)
echo -e "${YELLOW}Billing_account_id của bạn là: $billing_account_id ${NC}"

# ---------------------------
# Bắt đầu tạo + warm-up
# ---------------------------
for ((i = 0; i < 3; i++)); do
  project_id=$(generate_project_id)
  project_name=$(generate_project_name)

  if [ -n "$organization_id" ]; then
    gcloud projects create "$project_id" --name="$project_name" --organization="$organization_id"
  else
    gcloud projects create "$project_id" --name="$project_name"
  fi

  sleep 2
  gcloud alpha billing projects link "$project_id" --billing-account="$billing_account_id"
  gcloud config set project "$project_id"
  echo -e "${ORANGE}Đã tạo dự án '$project_name' (ID: $project_id).${NC}"
done

