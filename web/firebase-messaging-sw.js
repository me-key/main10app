importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDPxxi1R2erACFbtNMD_JKr13ftKiymrKg",
  appId: "1:758403612814:web:5e7e385bba4044917c49df",
  messagingSenderId: "758403612814",
  projectId: "main10app-1c326",
  authDomain: "main10app-1c326.firebaseapp.com",
  storageBucket: "main10app-1c326.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
