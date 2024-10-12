import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";
import { getDatabase } from "firebase/database";
const firebaseConfig = {
  apiKey: "AIzaSyCuLj8y7eIIigK1eFCb5yOBdKa8m7lgQvE",
  authDomain: "claim-safe2.firebaseapp.com",
  databaseURL: "https://claim-safe2-default-rtdb.firebaseio.com",
  projectId: "claim-safe2",
  storageBucket: "claim-safe2.appspot.com",
  messagingSenderId: "99961129299",
  appId: "1:99961129299:web:99ad80e601652c0ac8b9a6"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth();
export const storage = getStorage(app);
export const database = getDatabase(app);