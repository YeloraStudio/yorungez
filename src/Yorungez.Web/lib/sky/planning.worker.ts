/// <reference lib="webworker" />
import {buildObservingPlan} from './planning.ts';
self.onmessage=event=>{try{const {context,zone,date}=event.data;self.postMessage({type:'plan',plan:buildObservingPlan(context,zone,date)})}catch{self.postMessage({type:'error'})}};
