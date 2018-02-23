const gulp = require('gulp');
const path = require('path');
const shell = require('shelljs');
const argv = require('yargs').argv;
const fs = require('fs-extra');

const DOCKER = 'docker'; // docker command
const DOCKER_IMAGE_DEFAULT = 'ubnt/unms-private-fluentd';
const DOCKER_CONTAINER_DEFAULT = 'unms-fluentd';
const DOCKER_TAG_DEFAULT = 'local';

const dockerTag = argv['docker-tag'] || DOCKER_TAG_DEFAULT;
const dockerImage = `${argv['docker-image'] || DOCKER_IMAGE_DEFAULT}:${dockerTag}`;
const dockerContainer = argv['docker-container'] || DOCKER_CONTAINER_DEFAULT;
const imageFile = argv['image-file'];

function exec(command, ignoreErrors = false) {
  if (shell.exec(command).code !== 0 && !ignoreErrors) {
    throw Error('Build step failed.');
  }
}

gulp.task('build', () => {
  exec(`${DOCKER} build --force-rm -t "${dockerImage}" .`);
});

gulp.task('publish', ['build'], () => {
  exec(`docker push "${dockerImage}"`);
});

gulp.task('save-image', () => {
  exec(`echo Saving image to ${imageFile}`);
  exec(`${DOCKER} image save --output "${imageFile}" "${dockerImage}"`);
});

gulp.task('run', ['stop', 'remove-container'], () => {
  const confDir = path.join(__dirname, '..', '..', 'install', 'conf');
  const logDir = path.join(__dirname, 'logs');
  fs.ensureDirSync(logDir);
  exec(`${DOCKER} run \
        --publish 24224:24224 \
        --env FLUENTD_UID=1000 \
        --volume "${confDir}:/etc/fluent:ro" \
        --volume "${logDir}:/fluentd/log" \
        --name "${dockerContainer}" \
        "${dockerImage}"`);
});

gulp.task('remove-image', () => {
  exec(`${DOCKER} rmi "${dockerImage}"`, true);
});

gulp.task('stop', () => {
  exec(`${DOCKER} stop "${dockerContainer}"`, true);
});

gulp.task('remove-container', () => {
  exec(`${DOCKER} rm "${dockerContainer}"`, true);
});

gulp.task('clean', ['stop', 'remove-container', 'remove-image']);

gulp.task('default', ['clean', 'build', 'run']);
