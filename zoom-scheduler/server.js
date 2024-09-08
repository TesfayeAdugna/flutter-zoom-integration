require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');


const app = express();
const port = 3000;
app.use(cors());

// Middleware to parse JSON bodies
app.use(express.json());

// Endpoint to create a Zoom meeting
app.post('/create-meeting', async (req, res) => {
  try {
    // Get the access token
    const accessToken = await getAccessToken();

    // Make the API call to Zoom
    const response = await axios.post(
      'https://api.zoom.us/v2/users/me/meetings',
      req.body, // Pass the request body from the client
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );

    // Send the response back to the client
    res.status(response.status).json(response.data);
  } catch (error) {
    console.error('Error creating meeting:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json(error.response?.data || { message: error.message });
  }
});

// Function to get the access token using Server-to-Server OAuth
async function getAccessToken() {
  const clientId = process.env.CLIENT_ID;
  const clientSecret = process.env.CLIENT_SECRET;
  const accountId = process.env.ACCOUNT_ID;
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const response = await axios.post(
    `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`,
    null,
    {
      headers: {
        Authorization: `Basic ${credentials}`,
      },
    }
  );

  return response.data.access_token;
}

app.listen(port, () => {
  console.log(`Proxy server running on port ${port}`);
});
