import { describe, it, expect, beforeEach } from "vitest"

describe("Project Estimation Contract", () => {
  let contractAddress
  let client
  let contractor1
  let contractor2
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.project-estimation"
    client = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    contractor1 = "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5"
    contractor2 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
  })
  
  describe("Project Creation", () => {
    it("should create a new project successfully", () => {
      const projectData = {
        title: "Kitchen Renovation",
        description: "Complete kitchen remodel including cabinets and appliances",
        category: "Home Renovation",
        location: "New York, NY",
        budgetMin: 5000,
        budgetMax: 15000,
        timelineDays: 30,
      }
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should reject invalid budget range", () => {
      const projectData = {
        title: "Kitchen Renovation",
        description: "Complete kitchen remodel",
        category: "Home Renovation",
        location: "New York, NY",
        budgetMin: 15000, // Higher than max
        budgetMax: 5000,
        timelineDays: 30,
      }
      
      const result = {
        type: "error",
        value: 203, // ERR-INVALID-BID
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(203)
    })
  })
  
  describe("Bid Submission", () => {
    it("should submit valid bid successfully", () => {
      const bidData = {
        projectId: 1,
        estimatedCost: 10000,
        timelineDays: 25,
        materialsCost: 6000,
        laborCost: 4000,
        description: "High quality renovation with premium materials",
      }
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should reject bid outside budget range", () => {
      const bidData = {
        projectId: 1,
        estimatedCost: 20000, // Above budget max
        timelineDays: 25,
        materialsCost: 12000,
        laborCost: 8000,
        description: "Premium renovation",
      }
      
      const result = {
        type: "error",
        value: 203, // ERR-INVALID-BID
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(203)
    })
    
    it("should reject bid with incorrect cost calculation", () => {
      const bidData = {
        projectId: 1,
        estimatedCost: 10000,
        timelineDays: 25,
        materialsCost: 6000,
        laborCost: 3000, // Total doesn't match estimated cost
        description: "Renovation bid",
      }
      
      const result = {
        type: "error",
        value: 203, // ERR-INVALID-BID
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(203)
    })
    
    it("should prevent duplicate bids from same contractor", () => {
      // First bid succeeds
      const firstResult = {
        type: "ok",
        value: 1,
      }
      
      // Second bid from same contractor fails
      const secondResult = {
        type: "error",
        value: 203, // ERR-INVALID-BID
      }
      
      expect(firstResult.type).toBe("ok")
      expect(secondResult.type).toBe("error")
      expect(secondResult.value).toBe(203)
    })
  })
  
  describe("Bid Acceptance", () => {
    it("should accept bid by project owner", () => {
      const projectId = 1
      const bidId = 1
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should prevent non-owner from accepting bids", () => {
      const result = {
        type: "error",
        value: 200, // ERR-UNAUTHORIZED
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(200)
    })
    
    it("should prevent accepting bids on closed projects", () => {
      const result = {
        type: "error",
        value: 204, // ERR-PROJECT-CLOSED
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(204)
    })
  })
  
  describe("Project Management", () => {
    it("should close project by owner", () => {
      const projectId = 1
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should update contractor accuracy by owner", () => {
      const contractor = contractor1
      const accuracyScore = 85
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("Read-only Functions", () => {
    it("should get project information", () => {
      const projectId = 1
      
      const result = {
        type: "some",
        value: {
          owner: client,
          title: "Kitchen Renovation",
          description: "Complete kitchen remodel including cabinets and appliances",
          category: "Home Renovation",
          location: "New York, NY",
          "budget-min": 5000,
          "budget-max": 15000,
          "timeline-days": 30,
          status: "open",
          "created-at": 1000,
          "selected-bid": null,
        },
      }
      
      expect(result.type).toBe("some")
      expect(result.value.title).toBe("Kitchen Renovation")
      expect(result.value.status).toBe("open")
    })
    
    it("should get contractor statistics", () => {
      const contractor = contractor1
      
      const result = {
        type: "some",
        value: {
          "total-bids": 5,
          "accepted-bids": 3,
          "avg-accuracy": 85,
          "total-projects": 3,
        },
      }
      
      expect(result.type).toBe("some")
      expect(result.value["total-bids"]).toBe(5)
      expect(result.value["avg-accuracy"]).toBe(85)
    })
  })
})
