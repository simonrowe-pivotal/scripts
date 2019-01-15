#!/bin/sh

# This script:
#   1) Reads microservices.list
#   2) Pushes each microservices to PCF
#       

source ./commons.sh

deploy()
{
  echo_msg "Deploying $1"
  cd $BASE_DIR/$1
  cf push -f build/manifest.yml
  if [ $? -eq 0 ]
  then
    echo "Successfully deployed $1"
  else
    echo "Could not deploy $1" >&2
    exit 1
  fi
}

autoscale()
{
  file="microServices.list"
  while IFS= read -r app
  do
    if [ ! "${app:0:1}" == "#" ]
    then
      app_name=`echo "$app" | cut -d " " -f 2`
      cf delete-autoscaling-rules $app_name --force
      cf enable-autoscaling $app_name
      cf configure-autoscaling $app_name autoscaler-manifest.yml
    fi
  done < "$file"
  wait
}

main()
{
  file="microServices.list"
  while IFS= read -r app
  do
    if [ ! "${app:0:1}" == "#" ]
    then
      deploy $app &
      sleep 8
    fi
  done < "$file"
  wait


  summaryOfApps
  summaryOfServices
}

main
autoscale

printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
exit 0
