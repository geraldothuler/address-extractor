module.exports = {
   apps: [
     {
       name: 'address-extractor',
       script: 'node_modules/next/dist/bin/next',
       args: 'start',
       instances: 'max',
       exec_mode: 'cluster',
       autorestart: true,
       watch: false,
       max_memory_restart: '1G',
       env: {
         NODE_ENV: 'production',
         PORT: 3000
       },
       env_production: {
         NODE_ENV: 'production',
         PORT: 3000
       },
       env_development: {
         NODE_ENV: 'development',
         PORT: 3000
       }
     }
   ]
 }
 