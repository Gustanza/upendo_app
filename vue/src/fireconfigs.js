// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyBBQf0DbEAOtFZk7paGD6hJymcbw83TH4o",
    authDomain: "moyoapptanzania-cf0e7.firebaseapp.com",
    projectId: "moyoapptanzania-cf0e7",
    storageBucket: "moyoapptanzania-cf0e7.firebasestorage.app",
    messagingSenderId: "630293487516",
    appId: "1:630293487516:web:7be24738f3212f60653259",
    measurementId: "G-VT1BP2PSZT"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);