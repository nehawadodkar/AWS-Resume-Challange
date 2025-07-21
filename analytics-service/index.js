const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

/// Allow only your website’s domain
app.use(cors({
  origin: 'https://cherry-blossom-dc123.neha-wadodkar.com',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type']
}));

// Configure AWS SDK (will use IAM role in ECS, but you can test locally with credentials)..
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

app.use(express.json());

app.post('/log-visit', async (req, res) => {
  const { timestamp, user_agent, referrer } = req.body;
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

  if (!timestamp || !ip || !user_agent) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const params = {
    TableName: process.env.DYNAMODB_TABLE || 'VisitAnalytics',
    Item: {
      id: `${timestamp}-${ip}`,
      timestamp,
      ip,
      user_agent,
      referrer: referrer || null,
    },
  };

  try {
    await dynamodb.put(params).promise();
    res.status(201).json({ message: 'Visit logged!' });
  } catch (err) {
    console.error('DynamoDB error:', err);
    res.status(500).json({ error: 'Could not log visit' });
  }
});

app.get('/', (req, res) => {
  res.send('Analytics Service is running!');
});

app.listen(port, () => {
  console.log(`Analytics service listening on port ${port}`);
});