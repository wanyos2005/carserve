#!/bin/bash

BASE_URL="http://localhost:8000/service-providers"

echo "======================"
echo " Seeding Data Started "
echo "======================"

# --- Provider categories ---
echo "---- Seeding Provider Categories ----"
PROVIDER_CATEGORIES=("Garage" "Insurance" "Car Wash" "Towing" "Tyres" "Spare Parts" "Painting" "Detailing" "Battery Shop" "Roadside Assistance")
for CAT in "${PROVIDER_CATEGORIES[@]}"; do
  curl -s -X POST $BASE_URL/categories/provider-categories \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$CAT\"}" | jq
done

# --- Service categories ---
echo "---- Seeding Service Categories ----"
SERVICE_CATEGORIES=("Insurance" "Basic Services" "Mechanical Services" "Procurement" "Emergency Services" "Cosmetic Services")
declare -A CATEGORY_MAP

for CAT in "${SERVICE_CATEGORIES[@]}"; do
  CREATED=$(curl -s -X POST $BASE_URL/categories/service-categories \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$CAT\"}")
  echo $CREATED | jq
  ID=$(echo $CREATED | jq -r '.id // empty')
  CATEGORY_MAP[$CAT]=$ID
done

# --- Services ---
echo "---- Seeding Services ----"
declare -A SERVICES=(
  ["Motor Insurance"]="Insurance"
  ["Insurance Claims Assistance"]="Insurance"
  ["Car Wash"]="Basic Services"
  ["Inspection"]="Basic Services"
  ["Oil Change"]="Basic Services"
  ["Tyre Rotation"]="Basic Services"
  ["Full Servicing"]="Basic Services"
  ["General Repair"]="Mechanical Services"
  ["Diagnostics"]="Mechanical Services"
  ["Battery Replacement"]="Mechanical Services"
  ["Electrical / Wiring"]="Mechanical Services"
  ["Spare Parts"]="Procurement"
  ["Tyres"]="Procurement"
  ["Towing / Breakdown Assistance"]="Emergency Services"
  ["Roadside Assistance"]="Emergency Services"
  ["Bodywork / Painting"]="Cosmetic Services"
  ["Detailing"]="Cosmetic Services"
)

declare -A SERVICE_IDS

for NAME in "${!SERVICES[@]}"; do
  CAT=${SERVICES[$NAME]}
  CAT_ID=${CATEGORY_MAP[$CAT]}
  CREATED=$(curl -s -X POST $BASE_URL/services \
    -H "Content-Type: application/json" \
    -d "{
          \"category_id\": $CAT_ID,
          \"name\": \"$NAME\",
          \"description\": \"$NAME service\",
          \"price_range\": \"KES 1000 - 5000\",
          \"requirements\": {\"booking\": true}
        }")
  echo $CREATED | jq
  ID=$(echo $CREATED | jq -r '.id // empty')
  SERVICE_IDS[$NAME]=$ID
done

# --- Providers ---
echo "---- Seeding Providers ----"

NAMES=("Mombasa Road Garage" "Westlands AutoCare" "Kilimani Car Wash" "Karen Tyre Centre" "Thika Road Towing" "Ngong Spare Parts" "Industrial Area Auto Paint" "Lavington Car Detailing" "CBD Battery Hub" "Eastleigh Roadside Assist")
ADDRESSES=("Mombasa Road, Nairobi" "Westlands, Nairobi" "Kilimani, Nairobi" "Karen, Nairobi" "Thika Road, Nairobi" "Ngong, Kajiado" "Industrial Area, Nairobi" "Lavington, Nairobi" "Nairobi CBD" "Eastleigh, Nairobi")
LATS=(-1.322 -1.266 -1.300 -1.328 -1.220 -1.375 -1.295 -1.290 -1.283 -1.280)
LNGS=(36.821 36.812 36.799 36.720 37.020 36.650 36.860 36.770 36.820 36.850)

SERVICE_NAMES=("${!SERVICE_IDS[@]}")

for i in {0..9}; do
  CATEGORY_ID=$(( (i % 10) + 1 ))

  COUNT=$(( (RANDOM % 2) + 2 )) # 2 or 3
  SELECTED=()
  USED=()

  while [ ${#SELECTED[@]} -lt $COUNT ]; do
    RAND_INDEX=$(( RANDOM % ${#SERVICE_NAMES[@]} ))
    RAND_SERVICE=${SERVICE_NAMES[$RAND_INDEX]}
    if [[ ! " ${USED[*]} " =~ " ${RAND_SERVICE} " ]]; then
      USED+=("$RAND_SERVICE")
      SELECTED+=("\"${SERVICE_IDS[$RAND_SERVICE]}\"")
    fi
  done

  # ✅ Proper JSON array
  SERVICE_LIST=$(printf '%s,' "${SELECTED[@]}")
  SERVICE_LIST="[${SERVICE_LIST%,}]"

  PROVIDER=$(curl -s -X POST $BASE_URL/ \
    -H "Content-Type: application/json" \
    -d "{
          \"category_id\": $CATEGORY_ID,
          \"name\": \"${NAMES[$i]}\",
          \"description\": \"${NAMES[$i]} provides reliable automotive services in Nairobi.\",
          \"location\": {
            \"address\": \"${ADDRESSES[$i]}\",
            \"lat\": ${LATS[$i]},
            \"lng\": ${LNGS[$i]}
          },
          \"contact_info\": {
            \"phone\": \"+25470000$((100+i))\",
            \"email\": \"provider$((i+1))@example.com\",
            \"website\": \"https://www.${NAMES[$i]// /}.co.ke\"
          },
          \"is_registered\": true,
          \"services\": $SERVICE_LIST
        }")

  echo "$PROVIDER" | jq
done
