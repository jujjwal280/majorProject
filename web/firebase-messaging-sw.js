importScripts('https://www.gstatic.com/firebasejs/10.5.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.5.2/firebase-messaging-compat.js');

importScripts('https://www.gstatic.com/firebasejs/10.5.2/firebase-app-compat.js');

 firebase.initializeApp({
    apiKey: 'AIzaSyDjdi_w2bKL0K_v_kNTbw4UYV47WZ0_OBA',
    appId: '1:369975490040:web:9a3a0f142bac029b2d120d',
    messagingSenderId: '369975490040',
    projectId: 'money-minder-3c702',
    authDomain: 'money-minder-3c702.firebaseapp.com',
    storageBucket: 'money-minder-3c702.firebasestorage.app',
    measurementId: 'G-D9WKEQYT1R',
});
const messaging = firebase.messaging();