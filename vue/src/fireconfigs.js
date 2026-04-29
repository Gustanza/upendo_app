import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
    apiKey: "AIzaSyBBQf0DbEAOtFZk7paGD6hJymcbw83TH4o",
    authDomain: "moyoapptanzania-cf0e7.firebaseapp.com",
    projectId: "moyoapptanzania-cf0e7",
    storageBucket: "moyoapptanzania-cf0e7.firebasestorage.app",
    messagingSenderId: "630293487516",
    appId: "1:630293487516:web:7be24738f3212f60653259",
    measurementId: "G-VT1BP2PSZT"
};

const app = initializeApp(firebaseConfig);
export const db   = getFirestore(app);
export const auth = getAuth(app);
