const reviewReminderJob = require('./reviewReminders');
const logger = require('../utils/logger');

/**
 * Initialize and start all cron jobs
 */
const startCronJobs = () => {
  logger.info('Starting cron jobs...');

  // Start review reminder job (runs hourly)
  reviewReminderJob.start();
  logger.info('Review reminder job started (runs hourly)');

  // Add more cron jobs here as needed
};

/**
 * Stop all cron jobs
 */
const stopCronJobs = () => {
  logger.info('Stopping cron jobs...');
  
  reviewReminderJob.stop();
  logger.info('Review reminder job stopped');

  // Stop other cron jobs here
};

module.exports = {
  startCronJobs,
  stopCronJobs
};