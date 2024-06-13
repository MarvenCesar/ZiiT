const functions = require('firebase-functions');
const StreamChat = require('stream-chat').StreamChat;

const apiKey = 'dtb2zae562wu';
const apiSecret = 'zhrrmsqdq3rr3s7y8jvbhvuz5u6efw89vubvvp9wpyhegbvyqfb6fj8s5bcwe7yq';
const serverClient = StreamChat.getInstance(apiKey, apiSecret);

exports.generateStreamToken = functions.https.onRequest((req, res) => {
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'Missing userId' });
  }

  try {
    const token = serverClient.createToken(userId);
    res.json({ token });
  } catch (error) {
    console.error('Error generating token:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


