# 📅 Resource Scheduling App

A mobile application built with **Flutter** that simulates **CPU scheduling algorithms** (FCFS, SJF, Priority – non-preemptive) in the context of **resource booking**.  
The app allows users to request organizational resources (e.g., rooms, laptops, chairs) and schedules them efficiently based on the chosen algorithm.  

---

## ✨ Features
- 🔑 **Authentication**: User login & signup  
- 🛠️ **Resource Management**: Add & manage resources (rooms, equipment, etc.)  
- 📥 **Request Handling**: Users can request resources with details like:
  - Resource type (e.g., Laptop, Room, Chair)
  - Priority (taken from user’s profile)
  - Burst Time (usage duration)
  - Arrival Time (when request is made)
- ⚙️ **Scheduling Algorithms**:
  - **FCFS** (First Come First Serve)
  - **SJF** (Shortest Job First - Non-preemptive)
  - **Priority Scheduling - Non-preemptive**
- 📊 **Gantt Chart View**: Visual timeline of scheduled requests  
- 📑 **Reports**: Export schedule reports (PDF/CSV)  

---

## 🖼️ System Overview

### Workflow
1. **User logs in**
2. **User submits resource request**
3. **Requests stored in SQLite database**
4. **Admin chooses scheduling algorithm**
5. **Scheduling module computes order**
6. **Gantt chart & schedule displayed on UI**
7. **Reports generated for analysis**

---

## 📐 System Diagram
```mermaid
flowchart TD
    A[User] -->|Login/Request| B[Flutter App UI]
    B --> C[SQLite Database]
    B --> D[Scheduling Module (FCFS/SJF/Priority)]
    D --> B
    B --> E[Report Generator (PDF/CSV)]
    E --> A
