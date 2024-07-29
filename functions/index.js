const functions = require('firebase-functions');
const StreamChat = require('stream-chat').StreamChat;

const apiKey = 'dtb2zae562wu';
const apiSecret = 'zhrrmsqdq3rr3s7y8jvbhvuz5u6efw89vubvvp9wpyhegbvyqfb6fj8s5bcwe7yq';
const serverClient = StreamChat.getInstance(apiKey, apiSecret);

exports.generateStreamToken = functions.https.onRequest(async (req, res) => {
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'Missing userId' });
  }

  try {
    const user = {
      id: userId,
      role: 'admin',
      channel_permissions: ['read', 'write', 'create', 'update', 'delete']
    };

    await serverClient.upsertUser(user);

    const token = serverClient.createToken(userId);

    res.json({ token: token });
  } catch (error) {
    console.error('Error generating token or updating user:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


