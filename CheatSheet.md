## Restarts payment-service and send a POST request with only a row sms/unparseable 
docker compose restart payment-service 2>&1 && sleep 5 && curl -s -w "\nHTTP %{http_code}" -X POST http://192.168.0.104:8000/payment-service/mpesa/transactions -H "Content-Type: application/json" -d '{"raw_sms":"Your M-PESA account balance is Ksh2,500.00. 17/03/26"}'

## testing payment delivery logic

curl -X POST http://192.168.0.104:8000/payment-service/mpesa/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_code": "TESTPIPE01",
    "raw_sms": "TESTPIPE01 Confirmed. You have received Ksh500.00 from TEST USER 0712345678 on 17/3/2026 at 10:00 AM. New M-PESA balance is Ksh1,000.00.",
    "amount": 500.00,
    "transaction_type": "received",
    "provider_id": "9a8b23c3-fb15-42bc-83a9-f239b0050bdb",
    "source": "sms_reader"
  }'
