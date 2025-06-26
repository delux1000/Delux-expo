const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 8080;

const LOCAL_TUNNEL_URL = 'https://iloveeverythinglikemoney.loca.lt';

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.all('*', async (req, res) => {
  try {
    const targetUrl = `${LOCAL_TUNNEL_URL}${req.originalUrl}`;

    const filteredHeaders = { ...req.headers };
    delete filteredHeaders.host;
    filteredHeaders['bypass-tunnel-reminder'] = '1';

    const response = await axios({
      method: req.method,
      url: targetUrl,
      headers: filteredHeaders,
      data: req.body,
      validateStatus: () => true,
    });

    res.status(response.status).set(response.headers).send(response.data);
  } catch (error) {
    console.error('Proxy error:', error.message);
    res.status(500).json({ error: 'Proxy failed', message: error.message });
  }
});

app.listen(port, () => {
  console.log(`Remote proxy listening at http://localhost:${port}`);
});
