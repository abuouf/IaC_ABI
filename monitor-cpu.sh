#!/bin/bash
# Get CPU UTILIZATION using top command 
CPU_UTILIZATION=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d "." -f1)
# check if CPU over 50% send an alert email
if [ "$CPU_UTILIZATION" -gt 50 ]; then
echo "High CPU Utilization: $CPU_UTILIZATION%" | mail -s "Alert: High CPU Utilization" abdallah.abuouf@gmail.com
fi
