'use strict';

const redis = require('redis');
const { size, has } = require('lodash/fp');
const { assoc } = require('ramda');
const bluebird = require('bluebird');

const redisConfig = {
  host: 'unms-redis',
  port: 6379,
};

const tableConfig = {
  deviceList: [
    'status', 'name', 'firmwareVersion', 'model', 'uptime', 'lastSeen', 'cpu', 'signal', 'assignedTo',
  ],
  endpointList: [
    'status', 'name', 'address', 'site',
  ],
  siteList: [
    'status', 'name', 'address',
  ],
  firmwareList: [
    'origin', 'models', 'version', 'name', 'size', 'date',
  ],
  discoveryDeviceList: [
    'status', 'name', 'model', 'ipAddress', 'macAddress', 'firmwareVersion', 'progress',
  ],
  deviceBackupList: [
    'name', 'date', 'time',
  ],
  deviceInterfaceList: [
    'status', 'name', 'type', 'poe', 'ip', 'SFP', 'rxrate', 'txrate', 'rxbytes', 'txbytes', 'dropped', 'errors',
  ],
  erouterStaticRouteList: [
    'type', 'description', 'destination', 'gateway', 'staticType', 'interface', 'distance', 'selected',
  ],
  erouterOspfRouteAreaList: [
    'id', 'type', 'networks',
  ],
  erouterOspfRouteInterfaceList: [
    'displayName', 'auth', 'cost',
  ],
  erouterDhcpLeaseList: [
    'type', 'idAddress', 'macAddress', 'expiration', 'serverName', 'leaseId', 'hostname',
  ],
  erouterDhcpServerList: [
    'status', 'name', 'interface', 'rangeStart', 'rangeEnd', 'poolSize', 'available', 'leases',
  ],
  deviceLogList: [
    'level', 'event', 'date', 'time',
  ],
  siteDeviceList: [
    'status', 'name', 'firmwareVersion', 'model', 'uptime', 'lastSeen', 'cpu', 'signal',
  ],
  siteEndpointList: [
    'name', 'status',
  ],
  oltOnuList: [
    'status', 'port', 'name', 'model', 'firmwareVersion', 'serialNumber', 'uptime', 'txRate', 'rxRate', 'distance',
    'signal',
  ],
};

const redisClient = redis.createClient(redisConfig);
redisClient.on('error', error => console.log(`Redis client error ${error}`));
bluebird.promisifyAll(redis.RedisClient.prototype);
bluebird.promisifyAll(redis.Multi.prototype);


const repairUserProfile = key => redisClient.getAsync(key)
  .then(JSON.parse)
  .then(userProfile => (has(['tableConfig'], userProfile)
    ? userProfile
    : assoc('tableConfig', tableConfig, userProfile))
  )
  .then(JSON.stringify)
  .then(userProfile => redisClient.setAsync(key, userProfile))
  .catch((error) => {
    console.log(`Failed to repair user profile ${key}. Continue.`);
    return true;
  });

const repairUserProfiles = (keys) => {
  console.log(`\nFound ${size(keys)} user profiles.`);
  if (size(keys) === 0) { return true }

  return Promise.all(keys.map(repairUserProfile));
};

redisClient.keysAsync('userProfile:*')
  .then(repairUserProfiles)
  .then(() => {
    console.log('Finished\n');
    return process.exit();
  })
  .catch((error) => {
    console.log('Error: ', error);
    process.exit(1);
  });